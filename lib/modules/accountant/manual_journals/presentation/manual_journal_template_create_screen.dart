import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/providers/manual_journal_provider.dart';
import 'package:zerpai_erp/modules/accountant/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_chart_of_accounts_account_model.dart'
    as coa;
import 'package:zerpai_erp/modules/accountant/manual_journals/models/manual_journal_model.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/providers/manual_journal_template_provider.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_lookup_models.dart'
    as lookup;
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/shared/models/account_node.dart' as shared;
import 'package:zerpai_erp/modules/accountant/repositories/accountant_repository.dart';
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart'
    as account_dropdown;
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart' as di;
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

class _JournalTemplateRow {
  String? accountId;
  String? accountName;
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController debitCtrl = TextEditingController(text: '');
  final TextEditingController creditCtrl = TextEditingController(text: '');
  String? contactId;
  String? contactType;
  String? contactName;
  String type = 'debit';
  bool isExpanded = false;
  String? projectId;
  String? reportingTags;
  double rowHeight = 48;

  void dispose() {
    descriptionCtrl.dispose();
    debitCtrl.dispose();
    creditCtrl.dispose();
  }
}

class JournalTemplateCreateScreen extends ConsumerStatefulWidget {
  const JournalTemplateCreateScreen({super.key});

  @override
  ConsumerState<JournalTemplateCreateScreen> createState() =>
      _JournalTemplateCreateScreenState();
}

class _JournalTemplateCreateScreenState
    extends ConsumerState<JournalTemplateCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _templateNameCtrl = TextEditingController();
  final TextEditingController _referenceCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  List<_JournalTemplateRow> _rows = [];
  List<String> _validationErrors = [];
  bool _enterAmount = false;
  bool _isSaving = false;
  String _reportingMethod = 'accrual_and_cash';
  late lookup.Currency _selectedCurrency = const lookup.Currency(
    id: 'default',
    code: 'INR',
    name: 'Indian Rupee',
    symbol: '₹',
  );
  double _totalDebit = 0;
  double _totalCredit = 0;
  double _difference = 0;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _addRow();
    _addRow();
  }

  @override
  void dispose() {
    _templateNameCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
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
    if (_reportingMethod != 'accrual_only') {
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
    if (id == null) return null;
    for (final node in nodes) {
      if (node.id == id) return node.name;
      final found = _findName(node.children, id);
      if (found != null) return found;
    }
    return null;
  }

  void _addRow() {
    final row = _JournalTemplateRow();
    row.debitCtrl.addListener(_calculateTotals);
    row.creditCtrl.addListener(_calculateTotals);
    setState(() {
      _rows = [..._rows, row];
    });
    _calculateTotals();
  }

  void _removeRow(int index) {
    if (_rows.length <= 2) return;
    final row = _rows[index];
    setState(() {
      _rows = [..._rows]..removeAt(index);
    });
    row.dispose();
    _calculateTotals();
  }

  void _calculateTotals() {
    double debit = 0;
    double credit = 0;
    for (final row in _rows) {
      debit += double.tryParse(row.debitCtrl.text.trim()) ?? 0;
      credit += double.tryParse(row.creditCtrl.text.trim()) ?? 0;
    }

    if (!mounted) return;
    setState(() {
      _totalDebit = debit;
      _totalCredit = credit;
      _difference = (_totalDebit - _totalCredit).abs();
    });
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
                      const Padding(
                        padding: EdgeInsets.only(top: 6, right: 8),
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

  Future<void> _saveTemplate() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? true)) return;

    List<String> errors = [];

    if (_notesCtrl.text.trim().isEmpty) {
      errors.add('Notes field cannot be left empty.');
    }

    if (_rows.any((row) => (row.accountId ?? '').isEmpty)) {
      errors.add('Please select account in all rows');
    }

    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final d = double.tryParse(row.debitCtrl.text) ?? 0;
      final c = double.tryParse(row.creditCtrl.text) ?? 0;

      if ((d > 0 || c > 0) && row.accountId == null) {
        errors.add('Please select an account for row ${i + 1}');
      }
      if (d > 0 && c > 0) {
        errors.add('Row ${i + 1} cannot have both Debit and Credit values.');
      }
    }

    if (errors.isNotEmpty) {
      setState(() => _validationErrors = errors);
      return;
    }

    setState(() {
      _validationErrors.clear();
      _isSaving = true;
    });

    try {
      final templateItems = _rows
          .map(
            (row) => ManualJournalTemplateItem(
              accountId: row.accountId!,
              accountName: row.accountName ?? '',
              description: row.descriptionCtrl.text.trim(),
              contactId: row.contactId,
              contactType: row.contactType,
              contactName: row.contactName,
              type: _enterAmount ? null : row.type,
              debit: _enterAmount
                  ? (double.tryParse(row.debitCtrl.text.trim()) ?? 0)
                  : 0,
              credit: _enterAmount
                  ? (double.tryParse(row.creditCtrl.text.trim()) ?? 0)
                  : 0,
              projectId: row.projectId,
              reportingTags: row.reportingTags,
            ),
          )
          .toList();

      final template = ManualJournalTemplate(
        id: '', // New template
        templateName: _templateNameCtrl.text.trim(),
        referenceNumber: _referenceCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        reportingMethod: _reportingMethod,
        currency: _selectedCurrency.code,
        enterAmount: _enterAmount,
        items: templateItems,
      );

      await ref
          .read(manualJournalTemplateProvider.notifier)
          .createTemplate(template);

      if (!mounted) return;

      ZerpaiToast.saved(context, 'Journal template');
      context.go(AppRoutes.accountantJournalTemplates);
    } catch (e) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(chartOfAccountsProvider);
    final bool compact = MediaQuery.of(context).size.width < 1050;

    return ZerpaiLayout(
      pageTitle: 'New Template',
      isDirty: _isDirty,
      enableBodyScroll: true,
      footer: _buildFooter(),
      child: Form(
        key: _formKey,
        onChanged: () {
          if (!_isDirty) setState(() => _isDirty = true);
        },
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_validationErrors.isNotEmpty) _buildValidationBanner(),
                _buildHeaderSection(compact),
                const SizedBox(height: 22),
                _buildItemsTable(accountsState.roots),
                if (_enterAmount) ...[
                  const SizedBox(height: 16),
                  _buildTotalsCard(),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool compact) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormRow(
              label: 'Template Name',
              required: true,
              compact: compact,
              tooltip:
                  'A descriptive name to easily identify and reuse this template',
              child: CustomTextField(
                controller: _templateNameCtrl,
                height: 44,
                maxLines: 1,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            _buildFormRow(
              label: 'Reference#',
              compact: compact,
              tooltip:
                  'Default internal reference number for generated journals',
              child: CustomTextField(controller: _referenceCtrl),
            ),
            _buildFormRow(
              label: 'Notes',
              required: true,
              compact: compact,
              tooltip:
                  'Standardized notes or description pre-filled in generated journals',
              child: CustomTextField(
                controller: _notesCtrl,
                maxLines: 6,
                height: 100,
                hintText: 'Max. 500 characters',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
            _buildFormRow(
              label: 'Reporting Method',
              compact: compact,
              tooltip:
                  'Choose whether you want this template to appear in reports generated on cash basis, accrual basis, or both.',
              child: ZerpaiRadioGroup<String>(
                options: const [
                  'accrual_and_cash',
                  'accrual_only',
                  'cash_only',
                ],
                current: _reportingMethod,
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
                  setState(() => _reportingMethod = value);
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
                              .where((c) => c.code == _selectedCurrency.code)
                              .firstOrNull ??
                          currencyList.first;

                      return di.FormDropdown<lookup.Currency>(
                        value: currentCurrency,
                        items: currencyList,
                        showSearch: true,
                        displayStringForValue: (c) => c.label,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCurrency = val);
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

  Widget _buildItemsTable(List<coa.AccountNode> roots) {
    final mappedNodes = _mapNodes(roots);
    const String contactHeader = 'CONTACT';
    const String debitHeader = 'DEBITS';
    const String creditHeader = 'CREDITS';

    final tableContainer = Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 6),
            child: Row(
              children: [
                const Spacer(),
                SizedBox(
                  height: 18,
                  width: 18,
                  child: Checkbox(
                    value: _enterAmount,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (v) {
                      setState(() => _enterAmount = v ?? false);
                      _calculateTotals();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Enter an amount',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.zero,
            height: 40,
            decoration: const BoxDecoration(
              color: AppTheme.tableHeaderBg,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                _cell(width: 32, child: const SizedBox()),
                _cell(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.only(left: 12),
                    alignment: Alignment.centerLeft,
                    child: Text('ACCOUNT', style: _tableHeaderStyle),
                  ),
                ),
                _cell(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.only(left: 12),
                    alignment: Alignment.centerLeft,
                    child: Text('DESCRIPTION', style: _tableHeaderStyle),
                  ),
                ),
                _cell(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.only(left: 12),
                    alignment: Alignment.centerLeft,
                    child: Text(contactHeader, style: _tableHeaderStyle),
                  ),
                ),
                if (_enterAmount) ...[
                  _cell(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.only(right: 12),
                      alignment: Alignment.centerRight,
                      child: Text(debitHeader, style: _tableHeaderStyle),
                    ),
                  ),
                  _cell(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.only(right: 12),
                      alignment: Alignment.centerRight,
                      child: Text(creditHeader, style: _tableHeaderStyle),
                    ),
                  ),
                ] else ...[
                  _cell(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.only(left: 12),
                      alignment: Alignment.centerLeft,
                      child: Text('TYPE', style: _tableHeaderStyle),
                    ),
                  ),
                ],
                _cell(
                  width: 80,
                  isLast: true,
                  child: Center(
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        LucideIcons.moreVertical,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        setState(() {
                          final expand = value == 'show';
                          for (var row in _rows) {
                            row.isExpanded = expand;
                          }
                        });
                      },
                      itemBuilder: (context) {
                        final allExpanded =
                            _rows.isNotEmpty &&
                            _rows.every((r) => r.isExpanded);
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
                ),
              ],
            ),
          ),
          ReorderableListView.builder(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rows.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _rows.removeAt(oldIndex);
                _rows.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final row = _rows[index];
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
                                account_dropdown.AccountTreeDropdown(
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
                                      final type =
                                          e.accountType.toLowerCase().trim();

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
                                      if (_reportingMethod != 'accrual_only') {
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
                                  onChanged: (v) {
                                    setState(() {
                                      row.accountId = v;
                                      row.accountName = _findName(mappedNodes, v);
                                      row.rowHeight = _isGstAccount(row.accountName) ? 75.0 : 48.0;
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
                            flex: 3,
                            child: CustomTextField(
                              controller: row.descriptionCtrl,
                              hintText: 'Description',
                              borderRadius: BorderRadius.zero,
                              border: Border.all(color: Colors.transparent),
                              maxLines: null,
                              resizable: true,
                              height: row.rowHeight - 2,
                              minHeight: 40,
                              onHeightChanged: (h) => setState(() => row.rowHeight = h + 2),
                              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                            ),
                          ),
                          _cell(
                            flex: 2,
                            child: ref
                                .watch(manualJournalContactsProvider)
                                .when(
                                  data: (contacts) =>
                                      di.FormDropdown<Map<String, dynamic>>(
                                        value: contacts
                                                .where(
                                                  (c) =>
                                                      c['id'] ==
                                                          row.contactId &&
                                                      (row.contactType ==
                                                               null ||
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
                                                  (c) =>
                                                      c['id'] == row.contactId,
                                                )
                                                .firstOrNull,
                                        hint: 'Select Contact',
                                        showSearch: true,
                                        borderRadius: BorderRadius.zero,
                                        border: Border.all(color: Colors.transparent),
                                        height: 48,
                                        items: contacts
                                            .map(
                                              (c) =>
                                                  Map<String, dynamic>.from(c),
                                            )
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
                                                v?['contact_type'] ??
                                                v?['type'];
                                            row.contactType = typeValue
                                                ?.toString();
                                            row.contactName =
                                                (v?['displayName'] ??
                                                        v?['display_name'] ??
                                                        '')
                                                    .toString();
                                          });
                                        },
                                      ),
                                  loading: () => const SizedBox(height: 20),
                                  error: (_, __) =>
                                      di.FormDropdown<Map<String, dynamic>>(
                                        value: null,
                                        items: const [],
                                        hint: 'Select Contact',
                                        onChanged: _noopContactChange,
                                      ),
                                ),
                          ),
                          if (_enterAmount) ...[
                            _cell(
                              flex: 2,
                              child: CustomTextField(
                                controller: row.debitCtrl,
                                textAlign: TextAlign.right,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
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
                                  final credit =
                                      double.tryParse(row.creditCtrl.text) ?? 0;
                                  if (debit > 0 && credit > 0) {
                                    row.creditCtrl.text = '';
                                  }
                                },
                              ),
                            ),
                            _cell(
                              flex: 2,
                              child: CustomTextField(
                                controller: row.creditCtrl,
                                textAlign: TextAlign.right,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
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
                                  final debit =
                                      double.tryParse(row.debitCtrl.text) ?? 0;
                                  if (credit > 0 && debit > 0) {
                                    row.debitCtrl.text = '';
                                  }
                                },
                              ),
                            ),
                          ] else ...[
                            _cell(
                              flex: 1,
                              child: di.FormDropdown<String>(
                                value: row.type,
                                items: const ['debit', 'credit'],
                                showSearch: true,
                                borderRadius: BorderRadius.zero,
                                border: Border.all(color: Colors.transparent),
                                height: 48,
                                displayStringForValue: (v) =>
                                    v == 'debit' ? 'Debit' : 'Credit',
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => row.type = value);
                                },
                              ),
                            ),
                          ],
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 22),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
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
                                        onChanged: (v) => setState(
                                          () => row.reportingTags = v,
                                        ),
                                        height: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: _enterAmount
                                  ? 6
                                  : 3, // filler for Contact + Debit/Credit/Type
                              child: const SizedBox(),
                            ),
                            const SizedBox(width: 80), // filler for actions
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
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

  Widget _buildTotalsCard() {
    final card = Container(
      width: 540,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.bgLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _summaryLine(
            'Sub Total',
            leftText: _totalDebit.toStringAsFixed(2),
            rightText: _totalCredit.toStringAsFixed(2),
            textColor: AppTheme.textSecondary,
          ),
          const SizedBox(height: 12),
          _summaryLine(
            'Total (${(_selectedCurrency.symbol?.trim().isNotEmpty ?? false) ? _selectedCurrency.symbol : _selectedCurrency.code})',
            leftText: _totalDebit.toStringAsFixed(2),
            rightText: _totalCredit.toStringAsFixed(2),
            bold: true,
          ),
          const SizedBox(height: 12),
          _summaryLine(
            'Difference',
            leftText: '',
            rightText: _difference.toStringAsFixed(2),
            textColor: _difference.abs() >= 0.01
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
    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.accountantJournalTemplates),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.borderColor),
              foregroundColor: AppTheme.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveTemplate,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(_isSaving ? 'Saving...' : 'Save'),
          ),
        ],
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

  Widget _cell({
    Widget? child,
    double? width,
    int? flex,
    bool isLast = false,
  }) {
    return Expanded(
      flex: flex ?? 0,
      child: Container(
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(right: BorderSide(color: AppTheme.borderColor)),
        ),
        child: child,
      ),
    );
  }

  static void _noopContactChange(Map<String, dynamic>? _) {}

  static const _tableHeaderStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 11,
    color: AppTheme.textSecondary,
  );
}

class _GstWarningWidget extends StatefulWidget {
  const _GstWarningWidget();

  @override
  State<_GstWarningWidget> createState() => _GstWarningWidgetState();
}

class _GstWarningWidgetState extends State<_GstWarningWidget> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _togglePopover() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    setState(() {});
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePopover,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: 320,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: 4,
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.alertTriangle,
                            size: 16,
                            color: Color(0xFFFF5252),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tax Compliance Notice',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Direct journal entries to GST accounts should be avoided for normal business transactions. Please use the dedicated GST modules for accurate compliance reporting.',
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
