import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/routing/app_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/credit_note_bulk_update_dialog.dart';
import 'package:zerpai_erp/modules/sales/credit_note/presentation/pages/column_customizer.dart';

class CreditNotesOverviewPage extends StatefulWidget {
  const CreditNotesOverviewPage({super.key});

  @override
  State<CreditNotesOverviewPage> createState() =>
      _CreditNotesOverviewPageState();
}

class _CreditNotesOverviewPageState extends State<CreditNotesOverviewPage> {
  static const double _tableWidth = 1920;

  final _rows = <_CreditNoteRow>[
    _CreditNoteRow(
      date: '15-05-2026',
      location: 'ZABNIX PRIVATE LIMITED',
      creditNoteNumber: 'CN-00011',
      referenceNumber: '-',
      customerName: 'CUS-1',
      invoiceNumber: 'INV-000082',
      status: 'OPEN',
      amount: '0.00',
      balance: '0.00',
      issueDate: '15-05-2026',
      salesPerson: '-',
    ),
  ];

  final ScrollController _horizontalScrollController = ScrollController();
  String _selectedView = 'All';
  bool _dropdownOpen = false;
  bool _columnMenuOpen = false;
  final Set<int> _selectedIndices = {};
  List<ColumnConfig> _columns = _defaultColumns();

  static const _viewOptions = [
    'All',
    'Draft',
    'Locked',
    'Pending Approval',
    'Approved',
    'Open',
    'Closed',
    'Void',
    'Invoice unassociated',
  ];

  bool get _allSelected =>
      _rows.isNotEmpty && _selectedIndices.length == _rows.length;
  bool get _someSelected =>
      _selectedIndices.isNotEmpty && _selectedIndices.length < _rows.length;
  List<ColumnConfig> get _visibleColumns {
    final columns = _columns
        .where((c) => c.isVisible)
        .map((c) => c.copy())
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return columns;
  }

  static List<ColumnConfig> _defaultColumns() => [
        ColumnConfig(
          id: 'date',
          label: 'Date',
          orderIndex: 0,
          isLocked: true,
        ),
        ColumnConfig(
          id: 'location',
          label: 'Location',
          orderIndex: 1,
        ),
        ColumnConfig(
          id: 'creditNoteNumber',
          label: 'Credit Note#',
          orderIndex: 2,
          isLocked: true,
        ),
        ColumnConfig(
          id: 'referenceNumber',
          label: 'Reference#',
          orderIndex: 3,
        ),
        ColumnConfig(
          id: 'customerName',
          label: 'Customer Name',
          orderIndex: 4,
        ),
        ColumnConfig(
          id: 'invoiceNumber',
          label: 'Invoice#',
          orderIndex: 5,
        ),
        ColumnConfig(
          id: 'status',
          label: 'Status',
          orderIndex: 6,
        ),
        ColumnConfig(
          id: 'amount',
          label: 'Amount',
          orderIndex: 7,
        ),
        ColumnConfig(
          id: 'balance',
          label: 'Balance',
          orderIndex: 8,
        ),
        ColumnConfig(
          id: 'issueDate',
          label: 'Issue Date',
          orderIndex: 9,
        ),
        ColumnConfig(
          id: 'salesPerson',
          label: 'Sales Person',
          orderIndex: 10,
        ),
      ];

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIndices.addAll(List.generate(_rows.length, (i) => i));
      } else {
        _selectedIndices.clear();
      }
    });
  }

  void _toggleRow(int index, bool? value) {
    setState(() {
      if (value == true) {
        _selectedIndices.add(index);
      } else {
        _selectedIndices.remove(index);
      }
    });
  }

  void _openColumnCustomizer() {
    setState(() => _columnMenuOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => ColumnCustomizerDialog(
          columns: _columns,
          onSave: (columns) {
            setState(() {
              _columns = columns.map((c) => c.copy()).toList();
            });
            Navigator.of(dialogContext, rootNavigator: true).pop();
          },
        ),
      );
    });
  }

  void _openBulkUpdateDialog() {
    showCreditNoteBulkUpdateDialog(context);
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useTopPadding: false,
      useHorizontalPadding: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_dropdownOpen || _columnMenuOpen) {
            setState(() {
              _dropdownOpen = false;
              _columnMenuOpen = false;
            });
          }
        },
        child: Container(
          color: AppTheme.backgroundColor,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _selectedIndices.isNotEmpty
                      ? _buildBulkToolbar()
                      : _buildToolbar(context),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  Expanded(
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      scrollbarOrientation: ScrollbarOrientation.bottom,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width,
                          ),
                          child: SizedBox(
                            width: _tableWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _CnTableHeader(
                                  allSelected: _allSelected,
                                  someSelected: _someSelected,
                                  hasSelection: _selectedIndices.isNotEmpty,
                                  onSelectAll: _toggleSelectAll,
                                  columnMenuOpen: _columnMenuOpen,
                                  onColumnMenuTap: () => setState(() {
                                    _dropdownOpen = false;
                                    _columnMenuOpen = !_columnMenuOpen;
                                  }),
                                  columns: _visibleColumns,
                                ),
                                const Divider(
                                  height: 1,
                                  color: AppTheme.borderLight,
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: _rows.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(
                                      height: 1,
                                      color: AppTheme.borderLight,
                                    ),
                                    itemBuilder: (context, index) =>
                                        _CnTableRow(
                                      row: _rows[index],
                                      selected: _selectedIndices
                                          .contains(index),
                                      hasSelection:
                                          _selectedIndices.isNotEmpty,
                                      onChanged: (v) =>
                                          _toggleRow(index, v),
                                      columns: _visibleColumns,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Dropdown overlay
              if (_dropdownOpen)
                Positioned(
                  top: 60,
                  left: 24,
                  child: Material(
                    elevation: 0,
                    color: Colors.transparent,
                    child: Container(
                      width: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ..._viewOptions.map(
                            (opt) => _ViewFilterOption(
                              label: opt,
                              selected: opt == _selectedView,
                              onTap: () => setState(() {
                                _selectedView = opt;
                                _dropdownOpen = false;
                              }),
                            ),
                          ),
                          const Divider(height: 1, color: AppTheme.borderLight),
                          InkWell(
                            onTap: () =>
                                setState(() => _dropdownOpen = false),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LucideIcons.plus,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'New Custom View',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_columnMenuOpen)
                Positioned(
                  top: 90,
                  left: 14,
                  child: Material(
                    elevation: 0,
                    color: AppTheme.backgroundColor.withValues(alpha: 0),
                    child: Container(
                      width: 172,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.textPrimary.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ColumnMenuOption(
                            label: 'Customize Columns',
                            icon: LucideIcons.columns,
                            selected: true,
                            onTap: _openColumnCustomizer,
                          ),
                          _ColumnMenuOption(
                            label: 'Clip Text',
                            icon: LucideIcons.alignJustify,
                            onTap: () {
                              setState(() => _columnMenuOpen = false);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedView == 'All' ? 'All Credit Notes' : _selectedView,
                  style: AppTheme.pageTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _dropdownOpen
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  size: 18,
                  color: AppTheme.primaryBlueDark,
                ),
              ],
            ),
          ),
          const Spacer(),
          ZButton.primary(
            label: 'New',
            icon: LucideIcons.plus,
            onPressed: () => context.go(AppRoutes.creditNotesCreate),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.moreHorizontal, size: 18),
              onPressed: () {},
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkToolbar() {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Bulk Update
          _BulkActionButton(
            label: 'Bulk Update',
            onTap: _openBulkUpdateDialog,
          ),
          const SizedBox(width: 8),
          // Download with chevron
          _BulkActionButton(
            icon: LucideIcons.download,
            trailingIcon: LucideIcons.chevronDown,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          // Print
          _BulkActionButton(
            icon: LucideIcons.printer,
            onTap: () {},
          ),
          // Separator
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.borderLight,
          ),
          // Delete
          _BulkActionButton(
            label: 'Delete',
            onTap: () {
              setState(() {
                final sorted = _selectedIndices.toList()
                  ..sort((a, b) => b.compareTo(a));
                for (final i in sorted) {
                  _rows.removeAt(i);
                }
                _selectedIndices.clear();
              });
            },
          ),
          // Separator
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.borderLight,
          ),
          // Count badge
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${_selectedIndices.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          // Clear selection X
          GestureDetector(
            onTap: () => setState(() => _selectedIndices.clear()),
            child: const Icon(
              LucideIcons.x,
              size: 20,
              color: Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkActionButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  const _BulkActionButton({
    this.label,
    this.icon,
    this.trailingIcon,
    required this.onTap,
  });

  @override
  State<_BulkActionButton> createState() => _BulkActionButtonState();
}

class _BulkActionButtonState extends State<_BulkActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                : Colors.transparent,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: 16, color: AppTheme.textPrimary),
              if (widget.icon != null && widget.label != null)
                const SizedBox(width: 6),
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.trailingIcon,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewFilterOption extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ViewFilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ViewFilterOption> createState() => _ViewFilterOptionState();
}

class _ViewFilterOptionState extends State<_ViewFilterOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppTheme.primaryBlue
                : _hovered
                    ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              if (widget.selected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        widget.selected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
              Icon(
                LucideIcons.star,
                size: 14,
                color: widget.selected
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.borderLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColumnMenuOption extends StatefulWidget {
  const _ColumnMenuOption({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_ColumnMenuOption> createState() => _ColumnMenuOptionState();
}

class _ColumnMenuOptionState extends State<_ColumnMenuOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final filled = _hovered;
    final foreground = filled
        ? AppTheme.backgroundColor
        : widget.selected
            ? AppTheme.primaryBlue
            : AppTheme.textPrimary;
    final iconColor = filled ? foreground : AppTheme.primaryBlue;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 32,
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: filled
                ? AppTheme.primaryBlue.withValues(alpha: 0.9)
                : AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: filled
                ? Border.all(
                    color: AppTheme.primaryBlueDark,
                    width: 2,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: foreground,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CnTableHeader extends StatelessWidget {
  final bool allSelected;
  final bool someSelected;
  final bool hasSelection;
  final ValueChanged<bool?> onSelectAll;
  final bool columnMenuOpen;
  final VoidCallback onColumnMenuTap;
  final List<ColumnConfig> columns;

  const _CnTableHeader({
    required this.allSelected,
    required this.someSelected,
    required this.hasSelection,
    required this.onSelectAll,
    required this.columnMenuOpen,
    required this.onColumnMenuTap,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppTheme.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!hasSelection)
            SizedBox(
              width: 28,
              child: GestureDetector(
                onTap: onColumnMenuTap,
                child: Icon(
                  LucideIcons.slidersHorizontal,
                  size: 16,
                  color: columnMenuOpen
                      ? AppTheme.primaryBlueDark
                      : AppTheme.primaryBlue,
                ),
              ),
            ),
          SizedBox(
            width: 32,
            child: Checkbox(
              value: allSelected ? true : (someSelected ? null : false),
              tristate: true,
              onChanged: (v) {
                // tristate cycles: null→true, true→false, false→true
                // We want: indeterminate or unchecked → select all, checked → deselect all
                onSelectAll(allSelected ? false : true);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
              visualDensity: VisualDensity.compact,
            ),
          ),
          for (final column in columns)
            _CnHeaderCell(
              width: _CnColumnWidths.forId(column.id),
              label: column.label.toUpperCase(),
              sorted: column.id == 'creditNoteNumber',
            ),
        ],
      ),
    );
  }
}

class _CnTableRow extends StatelessWidget {
  const _CnTableRow({
    required this.row,
    required this.selected,
    required this.hasSelection,
    required this.onChanged,
    required this.columns,
  });
  final _CreditNoteRow row;
  final bool selected;
  final bool hasSelection;
  final ValueChanged<bool?> onChanged;
  final List<ColumnConfig> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: selected
          ? AppTheme.primaryBlue.withValues(alpha: 0.07)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!hasSelection) const SizedBox(width: 28),
          SizedBox(
            width: 32,
            child: Checkbox(
              value: selected,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
              visualDensity: VisualDensity.compact,
            ),
          ),
          for (final column in columns)
            _CnBodyCell(
              width: _CnColumnWidths.forId(column.id),
              child: _buildCell(column.id),
            ),
        ],
      ),
    );
  }

  Widget _buildCell(String id) {
    switch (id) {
      case 'date':
        return _CnBodyText(row.date);
      case 'location':
        return _CnBodyText(row.location);
      case 'creditNoteNumber':
        return _CnBodyText(
          row.creditNoteNumber,
          color: AppTheme.primaryBlueDark,
          fontWeight: FontWeight.w600,
        );
      case 'referenceNumber':
        return _CnBodyText(row.referenceNumber);
      case 'customerName':
        return _CnBodyText(row.customerName);
      case 'invoiceNumber':
        return _CnBodyText(row.invoiceNumber);
      case 'status':
        return _CnBodyText(
          row.status,
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w500,
        );
      case 'amount':
        return _CnBodyText(row.amount);
      case 'balance':
        return _CnBodyText(row.balance);
      case 'issueDate':
        return _CnBodyText(row.issueDate);
      case 'salesPerson':
        return _CnBodyText(row.salesPerson);
      default:
        return const _CnBodyText('-');
    }
  }
}

class _CnColumnWidths {
  static const double date = 140;
  static const double location = 300;
  static const double creditNoteNumber = 160;
  static const double referenceNumber = 160;
  static const double customerName = 200;
  static const double invoiceNumber = 160;
  static const double status = 140;
  static const double amount = 130;
  static const double balance = 130;
  static const double issueDate = 150;
  static const double salesPerson = 170;

  static double forId(String id) {
    switch (id) {
      case 'date':
        return date;
      case 'location':
        return location;
      case 'creditNoteNumber':
        return creditNoteNumber;
      case 'referenceNumber':
        return referenceNumber;
      case 'customerName':
        return customerName;
      case 'invoiceNumber':
        return invoiceNumber;
      case 'status':
        return status;
      case 'amount':
        return amount;
      case 'balance':
        return balance;
      case 'issueDate':
        return issueDate;
      case 'salesPerson':
        return salesPerson;
      default:
        return 140;
    }
  }
}

class _CnHeaderCell extends StatelessWidget {
  const _CnHeaderCell({
    required this.width,
    required this.label,
    this.sorted = false,
  });
  final double width;
  final String label;
  final bool sorted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          if (sorted) ...[
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronsUpDown,
              size: 14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ],
      ),
    );
  }
}

class _CnBodyCell extends StatelessWidget {
  const _CnBodyCell({required this.width, required this.child});
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: child);
}

class _CnBodyText extends StatelessWidget {
  const _CnBodyText(
    this.text, {
    this.color = AppTheme.textPrimary,
    this.fontWeight = FontWeight.w400,
  });
  final String text;
  final Color color;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13, fontWeight: fontWeight, color: color),
    );
  }
}

class _CreditNoteRow {
  const _CreditNoteRow({
    required this.date,
    required this.location,
    required this.creditNoteNumber,
    required this.referenceNumber,
    required this.customerName,
    required this.invoiceNumber,
    required this.status,
    required this.amount,
    required this.balance,
    required this.issueDate,
    required this.salesPerson,
  });

  final String date;
  final String location;
  final String creditNoteNumber;
  final String referenceNumber;
  final String customerName;
  final String invoiceNumber;
  final String status;
  final String amount;
  final String balance;
  final String issueDate;
  final String salesPerson;
}
