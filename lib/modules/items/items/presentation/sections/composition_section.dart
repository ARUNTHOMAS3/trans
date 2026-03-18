import 'package:flutter/material.dart';
import '../../models/item_composition_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_list_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

class CompositionSection extends StatefulWidget {
  final List<ItemComposition> initialRows;
  final List<Map<String, dynamic>> contentOptions;
  final List<Map<String, dynamic>> strengthOptions;
  final List<Map<String, dynamic>> buyingRuleOptions;
  final List<Map<String, dynamic>> drugScheduleOptions;
  final Map<String, String> lookupCache;
  final ValueChanged<List<ItemComposition>> onChanged;
  final ValueChanged<String?> onBuyingRuleChanged;
  final ValueChanged<String?> onDrugScheduleChanged;
  final String? initialBuyingRule;
  final String? initialDrugSchedule;

  final bool initialTrackActiveIngredients;
  final ValueChanged<bool>? onTrackActiveIngredientsChanged;

  final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
  onSyncContents;
  final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
  onSyncStrengths;
  final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
  onSyncBuyingRules;
  final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
  onSyncDrugSchedules;
  final Future<String?> Function(String lookupKey, Map<String, dynamic> item)?
  onDeleteCheck;
  final Future<List<Map<String, dynamic>>> Function(String query)?
  onContentSearch;
  final Future<List<Map<String, dynamic>>> Function(String query)?
  onStrengthSearch;
  final Future<List<Map<String, dynamic>>> Function(String query)?
  onBuyingRuleSearch;
  final Future<List<Map<String, dynamic>>> Function(String query)?
  onDrugScheduleSearch;
  final VoidCallback? onRefresh;

  const CompositionSection({
    super.key,
    this.initialRows = const [],
    this.contentOptions = const [],
    this.strengthOptions = const [],
    this.buyingRuleOptions = const [],
    this.drugScheduleOptions = const [],
    this.lookupCache = const {},
    required this.onChanged,
    required this.onBuyingRuleChanged,
    required this.onDrugScheduleChanged,
    this.initialBuyingRule,
    this.initialDrugSchedule,
    this.initialTrackActiveIngredients = true,
    this.onTrackActiveIngredientsChanged,
    this.onSyncContents,
    this.onSyncStrengths,
    this.onSyncBuyingRules,
    this.onSyncDrugSchedules,
    this.onDeleteCheck,
    this.onContentSearch,
    this.onStrengthSearch,
    this.onBuyingRuleSearch,
    this.onDrugScheduleSearch,
    this.onRefresh,
  });

  @override
  State<CompositionSection> createState() => _CompositionSectionState();
}

class _CompositionSectionState extends State<CompositionSection> {
  static const double _gap = 16;
  static const double _actionWidth = 40;
  static const int _fieldFlex = 6;
  static const double _singleFieldMaxWidth = 360;

  late List<ItemComposition> _rows;
  bool _trackActiveIngredients = true;

  String? _selectedBuyingRule;
  String? _selectedDrugSchedule;
  int? _hoveredIndex;

  // Cache to store full objects from search results to ensure they ARE available
  // for display even before the global state refreshes.
  final Map<String, Map<String, dynamic>> _searchResultsCache = {};

  @override
  void initState() {
    super.initState();
    _rows = widget.initialRows.isEmpty
        ? [ItemComposition()]
        : List<ItemComposition>.from(widget.initialRows);
    _selectedBuyingRule = widget.initialBuyingRule;
    _selectedDrugSchedule = widget.initialDrugSchedule;
    _trackActiveIngredients = widget.initialTrackActiveIngredients;
  }

  bool _areRowsEqual(List<ItemComposition> a, List<ItemComposition> b) {
    // If one is empty and the other is just one blank row, we consider them "equivalent"
    // for the purpose of initialization to avoid resetting user input.
    final listA = a.isEmpty ? [ItemComposition()] : a;
    final listB = b.isEmpty ? [ItemComposition()] : b;

    if (listA.length != listB.length) return false;
    for (int i = 0; i < listA.length; i++) {
      if (listA[i].contentId != listB[i].contentId ||
          listA[i].strengthId != listB[i].strengthId ||
          listA[i].contentName != listB[i].contentName ||
          listA[i].strengthName != listB[i].strengthName) {
        return false;
      }
    }
    return true;
  }

  @override
  void didUpdateWidget(CompositionSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_areRowsEqual(widget.initialRows, _rows)) {
      setState(() {
        _rows = widget.initialRows.isEmpty
            ? [ItemComposition()]
            : List<ItemComposition>.from(widget.initialRows);
      });
    }

    if (widget.initialBuyingRule != oldWidget.initialBuyingRule) {
      _selectedBuyingRule = widget.initialBuyingRule;
    }
    if (widget.initialDrugSchedule != oldWidget.initialDrugSchedule) {
      _selectedDrugSchedule = widget.initialDrugSchedule;
    }
    if (widget.initialTrackActiveIngredients !=
        oldWidget.initialTrackActiveIngredients) {
      _trackActiveIngredients = widget.initialTrackActiveIngredients;
    }
  }

  // ---------------- HELPERS ----------------

  void _sync() => widget.onChanged(List<ItemComposition>.from(_rows));

  void _updateRow(
    int index, {
    String? contentId,
    String? strengthId,
    bool clearContent = false,
    bool clearStrength = false,
  }) {
    final old = _rows[index];

    setState(() {
      _rows[index] = old.copyWith(
        contentId: clearContent ? null : (contentId ?? old.contentId),
        strengthId: clearStrength ? null : (strengthId ?? old.strengthId),
        // If ID changed, clear the associated joined name to force cache lookup
        contentName: (contentId != null || clearContent)
            ? null
            : old.contentName,
        strengthName: (strengthId != null || clearStrength)
            ? null
            : old.strengthName,
      );
      _sync();
    });
  }

  void _addRow() {
    setState(() {
      _rows.add(ItemComposition());
      _sync();
    });
  }

  void _removeRow(int index) {
    if (index == 0) return;
    setState(() {
      _rows.removeAt(index);
      _sync();
    });
  }

  Future<void> _openManage(
    String title,
    String label,
    String lookupKey,
    List<Map<String, dynamic>> list,
    String? selectedId,
    ValueChanged<String?> onSelect,
    Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
    onSync,
  ) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => ManageListDialog(
        title: title,
        singularLabel: label,
        headerLabel: label,
        items: list,
        selectedId: selectedId,
        onSelect: (value) {
          if (value is Map) {
            onSelect(value['id']);
          } else if (value is String) {
            onSelect(value);
          }
        },
        onSave: onSync,
        onDeleteCheck: widget.onDeleteCheck != null
            ? (item) => widget.onDeleteCheck!(lookupKey, item)
            : null,
      ),
    );

    // After dialog closes, ensure parent reloads fresh data
    if (widget.onRefresh != null && mounted) {
      widget.onRefresh!();
    }
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final buyingRuleTooltip = _lookupTooltip(
      widget.buyingRuleOptions,
      _selectedBuyingRule,
      [
        'rule_description',
        'system_behavior',
      ],
      extraLines: (selected) {
        final associatedCodes =
            (selected['associated_schedule_codes'] as List?)
                ?.whereType<Object?>()
                .map((value) => value.toString())
                .where((value) => value.trim().isNotEmpty)
                .join(', ') ??
            '';
        return [
          associatedCodes.isEmpty
              ? null
              : 'Associated Schedules: $associatedCodes',
          selected['requires_rx'] == true ? 'Requires Rx: Yes' : null,
          selected['requires_patient_info'] == true
              ? 'Requires Patient Info: Yes'
              : null,
          selected['log_to_special_register'] == true
              ? 'Special Register Logging: Yes'
              : null,
          selected['quantity_limit'] != null
              ? 'Quantity Limit: ${selected['quantity_limit']}'
              : null,
          selected['is_saleable'] == false ? 'Sale Allowed: No' : null,
        ];
      },
    );
    final drugScheduleTooltip = _lookupTooltip(
      widget.drugScheduleOptions,
      _selectedDrugSchedule,
      [
        'schedule_code',
        'reference_description',
      ],
      extraLines: (selected) => [
        selected['requires_prescription'] == true
            ? 'Requires Prescription: Yes'
            : null,
        selected['requires_h1_register'] == true
            ? 'Requires H1 Register: Yes'
            : null,
        selected['is_narcotic'] == true ? 'Narcotic Control: Yes' : null,
        selected['requires_batch_tracking'] == true
            ? 'Requires Batch Tracking: Yes'
            : null,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Track Active Ingredients
        Row(
          children: [
            Checkbox(
              value: _trackActiveIngredients,
              onChanged: (v) {
                final val = v ?? false;
                setState(() => _trackActiveIngredients = val);
                widget.onTrackActiveIngredientsChanged?.call(val);
              },
              activeColor: const Color(0xFF2563EB),
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Track Active Ingredients',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),

        if (_trackActiveIngredients) ...[
          const SizedBox(height: 12),
          _buildCompositionTable(),
        ],

        // Buying Rule
        const SizedBox(height: 20),
        _singleFieldRow(
          label: 'Buying Rule',
          tooltip: buyingRuleTooltip,
          child: _managedDropdown(
            value: _selectedBuyingRule,
            items: widget.buyingRuleOptions,
            hint: 'Select buying rule',
            manageLabel: 'Buying Rule',
            lookupKey: 'buying-rules',
            onSync: widget.onSyncBuyingRules,
            onSearch: widget.onBuyingRuleSearch,
            onChanged: (v) {
              setState(() => _selectedBuyingRule = v);
              widget.onBuyingRuleChanged(v);
            },
          ),
        ),

        // Schedule of Drug - Show Always
        const SizedBox(height: 16),
        _singleFieldRow(
          label: 'Schedule of Drug',
          tooltip: drugScheduleTooltip,
          child: _managedDropdown(
            value: _selectedDrugSchedule,
            items: widget.drugScheduleOptions,
            hint: 'Select drug schedule',
            manageLabel: 'Drug Schedule',
            lookupKey: 'drug-schedules',
            onSync: widget.onSyncDrugSchedules,
            onSearch: widget.onDrugScheduleSearch,
            onChanged: (v) {
              setState(() => _selectedDrugSchedule = v);
              widget.onDrugScheduleChanged(v);
            },
          ),
        ),
      ],
    );
  }

  // ---------------- TABLE ----------------

  Widget _buildCompositionTable() {
    return LayoutBuilder(
      builder: (context, c) {
        final bool mobile = c.maxWidth < 720;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!mobile)
                  Row(
                    children: const [
                      Expanded(flex: _fieldFlex, child: _Header('Contents')),
                      SizedBox(width: _gap),
                      Expanded(flex: _fieldFlex, child: _Header('Strength')),
                      SizedBox(width: _gap),
                      SizedBox(width: _actionWidth),
                    ],
                  ),

                if (!mobile) const SizedBox(height: 12),

                ..._rows.asMap().entries.map((e) {
                  final i = e.key;
                  final row = e.value;

                  if (mobile) return _mobileCard(i, row);

                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = i),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: _fieldFlex,
                            child: _cell(_contentField(i, row)),
                          ),
                          const SizedBox(width: _gap),
                          Expanded(
                            flex: _fieldFlex,
                            child: _cell(_strengthField(i, row)),
                          ),
                          const SizedBox(width: _gap),
                          SizedBox(
                            width: _actionWidth,
                            child: (i > 0 && _hoveredIndex == i)
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeRow(i),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const Divider(),
                TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- MOBILE CARD ----------------

  Widget _mobileCard(int index, ItemComposition row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stack('Contents', _contentField(index, row)),
          const SizedBox(height: 12),
          _stack('Strength', _strengthField(index, row)),
          if (index > 0)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _removeRow(index),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- FIELDS ----------------

  Widget _contentField(int i, ItemComposition row) => _managedDropdown(
    value: row.contentId,
    fallbackLabel: row.contentName,
    items: widget.contentOptions,
    hint: 'Select Content',
    manageLabel: 'Content',
    lookupKey: 'contents',
    onSync: widget.onSyncContents,
    onSearch: widget.onContentSearch,
    onChanged: (v) => _updateRow(i, contentId: v, clearContent: v == null),
  );

  Widget _strengthField(int i, ItemComposition row) => _managedDropdown(
    value: row.strengthId,
    fallbackLabel: row.strengthName,
    items: widget.strengthOptions,
    hint: 'Select Strength',
    manageLabel: 'Strength',
    lookupKey: 'strengths',
    onSync: widget.onSyncStrengths,
    onSearch: widget.onStrengthSearch,
    onChanged: (v) => _updateRow(i, strengthId: v, clearStrength: v == null),
  );

  // ---------------- COMMON DROPDOWN ----------------

  Widget _managedDropdown({
    String? value,
    String? fallbackLabel,
    required List<Map<String, dynamic>> items,
    required String hint,
    required String manageLabel,
    required String lookupKey,
    required ValueChanged<String?> onChanged,
    Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
    onSync,
    Future<List<Map<String, dynamic>>> Function(String query)? onSearch,
  }) {
    final List<Map<String, dynamic>> localItems = List.from(items);
    if (value != null && !localItems.any((i) => i['id'] == value)) {
      // Priority: 1. lookupCache, 2. fallbackLabel (from DB join)
      final label = widget.lookupCache[value] ?? fallbackLabel;

      if (label != null) {
        // Synthesize a minimal item so the dropdown finds a match
        localItems.add({
          'id': value,
          'name': label,
          'item_content': label,
          'content_name': label,
          'item_strength': label,
          'strength_name': label,
        });
      } else {
        // Fallback to ID if no label found (better than nothing/hint)
        // But only if it's not a long UUID
        final shortLabel = value.length > 8 ? value.substring(0, 8) : value;
        localItems.add({'id': value, 'name': shortLabel});
      }
    }

    return FormDropdown<String>(
      value: value,
      items: localItems.map((i) => i['id'] as String).toList(),
      hint: hint,
      allowClear: true,
      displayStringForValue: (val) {
        // 1. Try global options (now including our synthesized local one)
        final match = localItems.where((i) => i['id'] == val).firstOrNull;
        if (match != null) {
          return match['name'] ??
              match['buying_rule'] ??
              match['shedule_name'] ??
              match['schedule_name'] ??
              match['item_strength'] ??
              match['strength_name'] ??
              match['item_content'] ??
              match['content_name'] ??
              val;
        }

        // 2. Try search results cache
        final cached = _searchResultsCache[val];
        if (cached != null) {
          return cached['name'] ??
              cached['buying_rule'] ??
              cached['shedule_name'] ??
              cached['schedule_name'] ??
              cached['item_strength'] ??
              cached['strength_name'] ??
              cached['item_content'] ??
              cached['content_name'] ??
              val;
        }

        // 3. Try global lookup cache (from pre-joined fields)
        return widget.lookupCache[val] ?? val;
      },
      showSettings: true,
      settingsLabel: 'Manage $manageLabel',
      onSettingsTap: () => _openManage(
        'Manage $manageLabel',
        manageLabel,
        lookupKey,
        items,
        value,
        onChanged,
        onSync,
      ),
      onChanged: onChanged,
      onSearch: onSearch == null
          ? null
          : (q) async {
              final results = await onSearch(q);
              // Populate cache so displayStringForValue can find them immediately
              for (var r in results) {
                if (r.containsKey('id')) {
                  _searchResultsCache[r['id']] = r;
                }
              }
              return results.map((r) => r['id'] as String).toList();
            },
      itemBuilder: (id, isSelected, isHovered) {
        final match = localItems.where((i) => i['id'] == id).firstOrNull;
        final label =
            match?['name'] ??
            match?['buying_rule'] ??
            match?['shedule_name'] ??
            match?['schedule_name'] ??
            match?['item_strength'] ??
            match?['strength_name'] ??
            match?['item_content'] ??
            match?['content_name'] ??
            _searchResultsCache[id]?['name'] ??
            _searchResultsCache[id]?['buying_rule'] ??
            _searchResultsCache[id]?['shedule_name'] ??
            _searchResultsCache[id]?['schedule_name'] ??
            _searchResultsCache[id]?['item_strength'] ??
            _searchResultsCache[id]?['strength_name'] ??
            _searchResultsCache[id]?['item_content'] ??
            _searchResultsCache[id]?['content_name'] ??
            widget.lookupCache[id] ??
            id;

        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isHovered
                ? const Color(0xFF2563EB)
                : isSelected
                ? const Color(0xFFEFF6FF)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isHovered
                        ? Colors.white
                        : isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF111827),
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  size: 16,
                  color: isHovered ? Colors.white : const Color(0xFF2563EB),
                ),
            ],
          ),
        );
      },
    );
  }

  String? _lookupTooltip(
    List<Map<String, dynamic>> items,
    String? selectedId,
    List<String> baseFields, {
    List<String?> Function(Map<String, dynamic> selected)? extraLines,
  }) {
    if (selectedId == null || selectedId.isEmpty) return null;
    final selected = items.where((item) => item['id'] == selectedId).firstOrNull;
    if (selected == null) return null;

    final lines = <String?>[
      ...baseFields.map((field) => selected[field]?.toString()),
      ...(extraLines?.call(selected) ?? const []),
    ];

    final cleaned = lines
        .whereType<String>()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (cleaned.isEmpty) return null;
    return cleaned.join('\n');
  }

  // ---------------- LAYOUT HELPERS ----------------

  Widget _singleFieldRow({
    required String label,
    required Widget child,
    String? tooltip,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 720) return _stack(label, child);

        return Row(
          children: [
            SizedBox(
              width: 160,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (tooltip != null) ...[
                    const SizedBox(width: 6),
                    ZTooltip(message: tooltip),
                  ],
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _singleFieldMaxWidth),
              child: child,
            ),
          ],
        );
      },
    );
  }

  Widget _stack(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _cell(Widget child) {
    return SizedBox(height: 48, width: double.infinity, child: child);
  }
}

// ---------------- HEADER ----------------

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }
}
