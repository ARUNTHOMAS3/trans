import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart' as di;
import '../../models/recurring_journal_model.dart';
import '../../providers/recurring_journal_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';

enum RecurringJournalSortField { profileName, lastJournalDate, nextJournalDate, amount }

class RecurringJournalSortCommand {
  final RecurringJournalSortField field;
  final bool ascending;
  const RecurringJournalSortCommand({required this.field, required this.ascending});
}

enum _SortColumn { profileName, frequency, lastJournalDate, nextJournalDate, status, amount }

class RecurringJournalsListPanel extends ConsumerStatefulWidget {
  final bool compact;
  final String? initialSearchQuery;
  final ValueNotifier<RecurringJournalSortCommand?>? sortCommandListenable;

  const RecurringJournalsListPanel({
    super.key,
    this.compact = false,
    this.initialSearchQuery,
    this.sortCommandListenable,
  });

  @override
  ConsumerState<RecurringJournalsListPanel> createState() => _RecurringJournalsListPanelState();
}

class _RecurringJournalsListPanelState extends ConsumerState<RecurringJournalsListPanel> {
  static const double _minTableWidth = 1000;
  final List<_ColumnDef> _columns = _getDefaultColumns();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _horizontalScrollCtrl = ScrollController();

  _SortColumn _sortColumn = _SortColumn.profileName;
  bool _sortAscending = true;
  final Set<String> _checkedJournalIds = <String>{};
  int _pageSize = 50;
  int _pageIndex = 0;
  String _selectedFilter = 'all';

  static List<_ColumnDef> _getDefaultColumns() => [
    _ColumnDef(id: 'profileName', label: 'PROFILE NAME', flex: 20, sortColumn: _SortColumn.profileName, isLocked: true),
    _ColumnDef(id: 'frequency', label: 'FREQUENCY', flex: 12, sortColumn: _SortColumn.frequency),
    _ColumnDef(id: 'lastJournalDate', label: 'LAST JOURNAL DATE', flex: 14, sortColumn: _SortColumn.lastJournalDate),
    _ColumnDef(id: 'nextJournalDate', label: 'NEXT JOURNAL DATE', flex: 14, sortColumn: _SortColumn.nextJournalDate),
    _ColumnDef(id: 'status', label: 'STATUS', flex: 10, sortColumn: _SortColumn.status),
    _ColumnDef(id: 'notes', label: 'NOTES', flex: 6),
    _ColumnDef(id: 'amount', label: 'AMOUNT', flex: 12, sortColumn: _SortColumn.amount, textAlign: TextAlign.right, headerAlignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 12)),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) _searchCtrl.text = widget.initialSearchQuery!;
    widget.sortCommandListenable?.addListener(_handleExternalSortCommand);
  }

  @override
  void dispose() {
    widget.sortCommandListenable?.removeListener(_handleExternalSortCommand);
    _searchCtrl.dispose();
    _horizontalScrollCtrl.dispose();
    super.dispose();
  }

  void _handleExternalSortCommand() {
    final cmd = widget.sortCommandListenable?.value;
    if (cmd == null || !mounted) return;
    setState(() {
      _sortColumn = switch (cmd.field) {
        RecurringJournalSortField.profileName => _SortColumn.profileName,
        RecurringJournalSortField.lastJournalDate => _SortColumn.lastJournalDate,
        RecurringJournalSortField.nextJournalDate => _SortColumn.nextJournalDate,
        RecurringJournalSortField.amount => _SortColumn.amount,
      };
      _sortAscending = cmd.ascending;
      _pageIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recurringJournalProvider);
    final filtered = _filteredAndSorted(state.journals);
    final pageCount = math.max(1, (filtered.length / _pageSize).ceil());
    final effectivePageIndex = _pageIndex.clamp(0, pageCount - 1);
    final start = effectivePageIndex * _pageSize;
    final end = math.min(start + _pageSize, filtered.length);
    final paged = filtered.isEmpty ? <RecurringJournal>[] : filtered.sublist(start, end);

    if (widget.compact) return const Center(child: Text('Compact view not implemented'));

    return Column(
      children: [
        _buildTopBar(),
        const Divider(height: 1, color: AppTheme.borderColor),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = math.max(constraints.maxWidth, _minTableWidth);
              return Scrollbar(
                controller: _horizontalScrollCtrl,
                child: SingleChildScrollView(
                  controller: _horizontalScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        _buildTableHeader(paged),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        Expanded(
                          child: ListView.separated(
                            itemCount: paged.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderColor),
                            itemBuilder: (context, index) => _buildDataRow(paged[index], state.selectedJournalId),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildPagination(filtered.length, start + 1, end, pageCount),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text('All Recurring Journals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          SizedBox(
            width: 250,
            child: CustomTextField(
              controller: _searchCtrl,
              hintText: 'Search...',
              prefixIcon: LucideIcons.search,
              onChanged: (_) => setState(() => _pageIndex = 0),
            ),
          ),
          const SizedBox(width: 8),
          di.FormDropdown<String>(
            value: _selectedFilter,
            items: const ['all', 'active', 'stopped', 'expired'],
            onChanged: (val) => setState(() => _selectedFilter = val ?? 'all'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(List<RecurringJournal> paged) {
    final allChecked = paged.isNotEmpty && paged.every((j) => _checkedJournalIds.contains(j.id));
    final anyChecked = paged.any((j) => _checkedJournalIds.contains(j.id));
    final headerValue = paged.isEmpty ? false : (allChecked ? true : (anyChecked ? null : false));

    return Container(
      color: AppTheme.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Checkbox(
              value: headerValue,
              tristate: true,
              onChanged: (v) {
                setState(() {
                  if (v == true) _checkedJournalIds.addAll(paged.map((j) => j.id));
                  else _checkedJournalIds.clear();
                });
              },
            ),
          ),
          ..._columns.where((c) => c.isVisible).map((col) => Expanded(
            flex: col.flex,
            child: InkWell(
              onTap: col.sortColumn == null ? null : () {
                setState(() {
                  if (_sortColumn == col.sortColumn) _sortAscending = !_sortAscending;
                  else { _sortColumn = col.sortColumn!; _sortAscending = true; }
                  _pageIndex = 0;
                });
              },
              child: Padding(
                padding: col.padding,
                child: Row(
                  mainAxisAlignment: col.headerAlignment == Alignment.centerRight ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Text(col.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    if (_sortColumn == col.sortColumn) Icon(_sortAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown, size: 12),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDataRow(RecurringJournal journal, String? selectedId) {
    final checked = _checkedJournalIds.contains(journal.id);
    return InkWell(
      onTap: () => context.go(AppRoutes.accountantRecurringJournalsDetail.replaceAll(':id', journal.id)),
      child: Container(
        color: selectedId == journal.id ? AppTheme.primaryBlue.withValues(alpha: 0.05) : (checked ? AppTheme.bgLight : Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Checkbox(
                value: checked,
                onChanged: (v) => setState(() => v == true ? _checkedJournalIds.add(journal.id) : _checkedJournalIds.remove(journal.id)),
              ),
            ),
            ..._columns.where((c) => c.isVisible).map((col) {
              Widget cell;
              switch (col.id) {
                case 'profileName': cell = Text(journal.profileName, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w500)); break;
                case 'frequency': cell = Text(_formatFrequency(journal)); break;
                case 'lastJournalDate': cell = Text(journal.lastGeneratedDate != null ? DateFormat('dd MMM yyyy').format(journal.lastGeneratedDate!) : '-'); break;
                case 'nextJournalDate': cell = Text(DateFormat('dd MMM yyyy').format(_calculateNextRun(journal))); break;
                case 'status': cell = _StatusBadge(journal: journal); break;
                case 'notes': cell = journal.notes != null ? const Icon(LucideIcons.fileText, size: 14) : const SizedBox(); break;
                case 'amount': cell = Text(NumberFormat.currency(symbol: '₹').format(journal.totalDebit), textAlign: TextAlign.right); break;
                default: cell = const SizedBox();
              }
              return Expanded(
                flex: col.flex,
                child: Padding(
                  padding: col.padding,
                  child: Align(alignment: col.headerAlignment, child: cell),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(int total, int start, int end, int pageCount) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.borderColor))),
      child: Row(
        children: [
          Text('Total Journals: $total'),
          const Spacer(),
          IconButton(onPressed: _pageIndex > 0 ? () => setState(() => _pageIndex--) : null, icon: const Icon(LucideIcons.chevronLeft, size: 16)),
          Text('$start - $end of $total'),
          IconButton(onPressed: _pageIndex < pageCount - 1 ? () => setState(() => _pageIndex++) : null, icon: const Icon(LucideIcons.chevronRight, size: 16)),
        ],
      ),
    );
  }

  List<RecurringJournal> _filteredAndSorted(List<RecurringJournal> journals) {
    var list = journals.where((j) {
      if (_searchCtrl.text.isNotEmpty && !j.profileName.toLowerCase().contains(_searchCtrl.text.toLowerCase())) return false;
      if (_selectedFilter == 'active' && j.status != RecurringJournalStatus.active) return false;
      if (_selectedFilter == 'stopped' && j.status != RecurringJournalStatus.inactive) return false;
      return true;
    }).toList();

    list.sort((a, b) {
      int res = 0;
      switch (_sortColumn) {
        case _SortColumn.profileName: res = a.profileName.compareTo(b.profileName); break;
        case _SortColumn.amount: res = a.totalDebit.compareTo(b.totalDebit); break;
        case _SortColumn.lastJournalDate: res = (a.lastGeneratedDate ?? DateTime(0)).compareTo(b.lastGeneratedDate ?? DateTime(0)); break;
        case _SortColumn.nextJournalDate: res = _calculateNextRun(a).compareTo(_calculateNextRun(b)); break;
        case _SortColumn.frequency: res = a.repeatEvery.compareTo(b.repeatEvery); break;
        case _SortColumn.status: res = a.status.index.compareTo(b.status.index); break;
      }
      return _sortAscending ? res : -res;
    });
    return list;
  }

  String _formatFrequency(RecurringJournal j) => 'Every ${j.interval} ${j.repeatEvery}';

  DateTime _calculateNextRun(RecurringJournal j) {
    if (j.lastGeneratedDate == null) return j.startDate;
    final last = j.lastGeneratedDate!;
    if (j.repeatEvery.contains('week')) return last.add(Duration(days: 7 * j.interval));
    if (j.repeatEvery.contains('month')) return DateTime(last.year, last.month + j.interval, last.day);
    return last.add(Duration(days: j.interval));
  }
}

class _ColumnDef {
  final String id;
  final String label;
  final int flex;
  final _SortColumn? sortColumn;
  final bool isLocked;
  final TextAlign textAlign;
  final Alignment headerAlignment;
  final EdgeInsets padding;
  bool isVisible = true;

  _ColumnDef({
    required this.id, required this.label, required this.flex, this.sortColumn,
    this.isLocked = false, this.textAlign = TextAlign.left,
    this.headerAlignment = Alignment.centerLeft, this.padding = EdgeInsets.zero
  });
}

class _StatusBadge extends StatelessWidget {
  final RecurringJournal journal;
  const _StatusBadge({required this.journal});

  @override
  Widget build(BuildContext context) {
    final color = switch (journal.status) {
      RecurringJournalStatus.active => AppTheme.accentGreen,
      RecurringJournalStatus.inactive => AppTheme.textSecondary,
      RecurringJournalStatus.draft => AppTheme.primaryBlue,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(journal.status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _CustomizeColumnsDialog extends StatefulWidget {
  final List<_ColumnDef> columns;
  const _CustomizeColumnsDialog({required this.columns});
  @override
  State<_CustomizeColumnsDialog> createState() => _CustomizeColumnsDialogState();
}

class _CustomizeColumnsDialogState extends State<_CustomizeColumnsDialog> {
  late List<_ColumnDef> _temp;
  @override
  void initState() { super.initState(); _temp = List.from(widget.columns); }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Customize Columns', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._temp.map((c) => CheckboxListTile(
              title: Text(c.label),
              value: c.isVisible,
              onChanged: c.isLocked ? null : (v) => setState(() => c.isVisible = v ?? true),
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(onPressed: () => Navigator.pop(context, _temp), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white), child: const Text('Save')),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.borderColor)), child: const Text('Cancel')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
