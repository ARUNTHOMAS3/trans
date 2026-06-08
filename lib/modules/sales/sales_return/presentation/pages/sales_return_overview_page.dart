import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/app/routing/app_router.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class SalesReturnsOverviewPage extends ConsumerStatefulWidget {
  const SalesReturnsOverviewPage({super.key});

  @override
  ConsumerState<SalesReturnsOverviewPage> createState() =>
      _SalesReturnsOverviewPageState();
}

class _SalesReturnsOverviewPageState
    extends ConsumerState<SalesReturnsOverviewPage> {
  bool _isLoading = true;
  String? _error;
  List<_SalesReturnRow> _rows = const [];

  final Set<int> _selectedIndices = {};
  int? _detailIndex;

  final LayerLink _compactBulkLink = LayerLink();
  OverlayEntry? _compactBulkOverlay;

  bool get _allSelected =>
      _filteredRows.isNotEmpty &&
      _selectedIndices.length == _filteredRows.length;

  List<_SalesReturnRow> get _filteredRows => _rows;

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIndices.addAll(
          List.generate(_filteredRows.length, (i) => i),
        );
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

  List<dynamic> _extractSalesReturnsRows(dynamic payload) {
    if (payload is List) return payload;
    if (payload is! Map) return const [];
    final directData = payload['data'];
    if (directData is List) return directData;
    if (directData is Map) {
      final nestedData = directData['data'];
      if (nestedData is List) return nestedData;
      if (nestedData is Map<String, dynamic>) return [nestedData];
    }
    if (payload['id'] != null || payload['rma_number'] != null) {
      return [payload];
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  @override
  void dispose() {
    _compactBulkOverlay?.remove();
    super.dispose();
  }

  Future<void> _loadRows() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ref.read(apiClientProvider).get(
        'sales/returns',
        queryParameters: const {'page': 1, 'limit': 200},
      );
      final rawData = _extractSalesReturnsRows(response.data);
      final rows = rawData
          .whereType<Map<String, dynamic>>()
          .map(_SalesReturnRow.fromJson)
          .toList();
      if (!mounted) return;
      setState(() => _rows = rows);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load sales returns');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCompactBulkMenu(BuildContext context) {
    if (_compactBulkOverlay != null) return;
    final overlay = Overlay.of(context);
    _compactBulkOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeCompactBulkMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _compactBulkLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 38),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
              child: Container(
                width: 180,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SrMenuOption(
                      label: 'Export as PDF',
                      onTap: _closeCompactBulkMenu,
                    ),
                    _SrMenuOption(
                      label: 'Print',
                      onTap: _closeCompactBulkMenu,
                    ),
                    _SrMenuOption(
                      label: 'Delete',
                      onTap: () {
                        _closeCompactBulkMenu();
                        setState(() {
                          final sorted = _selectedIndices.toList()
                            ..sort((a, b) => b.compareTo(a));
                          final mutable = List<_SalesReturnRow>.from(_rows);
                          for (final i in sorted) {
                            mutable.removeAt(i);
                          }
                          _rows = mutable;
                          _selectedIndices.clear();
                          _detailIndex = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_compactBulkOverlay!);
  }

  void _closeCompactBulkMenu() {
    _compactBulkOverlay?.remove();
    _compactBulkOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useTopPadding: false,
      useHorizontalPadding: false,
      child: Container(
        color: AppTheme.backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_detailIndex == null) ...[
              _selectedIndices.isNotEmpty
                  ? _buildBulkToolbar()
                  : _SalesReturnsToolbar(onRefresh: _loadRows),
              const Divider(height: 1, color: AppTheme.borderLight),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width,
                    ),
                    child: SizedBox(
                      width: 1400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SalesReturnsTableHeader(
                            allSelected: _allSelected,
                            someSelected: _selectedIndices.isNotEmpty &&
                                !_allSelected,
                            onSelectAll: _toggleSelectAll,
                          ),
                          const Divider(height: 1, color: AppTheme.borderLight),
                          Expanded(child: _buildBody()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Expanded(child: _buildSplitView()),
            ],
          ],
        ),
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
          SizedBox(
            width: 28,
            child: Checkbox(
              value: _selectedIndices.isNotEmpty,
              tristate: false,
              onChanged: (v) =>
                  _toggleSelectAll(_allSelected ? false : true),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 12),
          _SrBulkActionButton(
            label: 'Export as PDF',
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _SrBulkActionButton(
            icon: LucideIcons.printer,
            onTap: () {},
          ),
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.borderLight,
          ),
          _SrBulkActionButton(
            label: 'Delete',
            onTap: () {
              setState(() {
                final sorted = _selectedIndices.toList()
                  ..sort((a, b) => b.compareTo(a));
                final mutable = List<_SalesReturnRow>.from(_rows);
                for (final i in sorted) {
                  mutable.removeAt(i);
                }
                _rows = mutable;
                _selectedIndices.clear();
              });
            },
          ),
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.borderLight,
          ),
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
          GestureDetector(
            onTap: () => setState(() => _selectedIndices.clear()),
            child: const Icon(LucideIcons.x, size: 20, color: Color(0xFFE53935)),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitView() {
    return Row(
      children: [
        _buildCompactList(),
        const VerticalDivider(width: 1, color: AppTheme.borderLight),
        Expanded(child: _buildDetailPanel()),
      ],
    );
  }

  Widget _buildCompactList() {
    return Container(
      width: 460,
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _selectedIndices.isNotEmpty
              ? _buildCompactBulkToolbar()
              : Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'All Sales Returns',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            context.go(AppRoutes.salesReturnsCreate),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(LucideIcons.plus,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : _rows.isEmpty
                    ? const Center(
                        child: Text(
                          'No sales returns found',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _filteredRows.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppTheme.borderLight),
                        itemBuilder: (context, index) => _SrCompactItem(
                          row: _filteredRows[index],
                          selected: index == _detailIndex,
                          checked: _selectedIndices.contains(index),
                          onCheckChanged: (v) => _toggleRow(index, v),
                          onTap: () =>
                              setState(() => _detailIndex = index),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBulkToolbar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: _selectedIndices.isNotEmpty,
              tristate: false,
              onChanged: (v) =>
                  _toggleSelectAll(_allSelected ? false : true),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          CompositedTransformTarget(
            link: _compactBulkLink,
            child: _SrBulkActionButton(
              label: 'Bulk Actions',
              trailingIcon: LucideIcons.chevronDown,
              onTap: () => _showCompactBulkMenu(context),
            ),
          ),
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppTheme.borderLight,
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${_selectedIndices.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _selectedIndices.clear()),
            child: const Icon(LucideIcons.x,
                size: 20, color: Color(0xFFE53935)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    final row = _filteredRows[_detailIndex!];
    return Container(
      color: AppTheme.bgLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Detail header
          Container(
            height: 64,
            padding: const EdgeInsets.only(left: 20, right: 8),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        row.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        row.rmaNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _detailIndex = null;
                    _selectedIndices.clear();
                  }),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(LucideIcons.x,
                        size: 20, color: AppTheme.errorRed),
                  ),
                ),
              ],
            ),
          ),
          // Action bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                _DetailActionBtn(
                  icon: LucideIcons.pencil,
                  label: 'Edit',
                  onTap: () =>
                      context.go(AppRoutes.salesReturnsCreate),
                ),
                const _DetailActionDivider(),
                _DetailActionBtn(
                  icon: LucideIcons.fileText,
                  label: 'PDF/Print',
                  onTap: () {},
                ),
                const _DetailActionDivider(),
                _DetailActionBtn(
                  icon: LucideIcons.moreHorizontal,
                  onTap: () {},
                ),
              ],
            ),
          ),
          // Detail body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'RMA#', value: row.rmaNumber),
                  _DetailRow(label: 'Date', value: row.date),
                  _DetailRow(label: 'Customer', value: row.customerName),
                  _DetailRow(label: 'Reference#', value: row.salesOrderNumber),
                  _DetailRow(label: 'Status', value: row.status),
                  _DetailRow(label: 'Receive Status', value: row.receiveStatus),
                  _DetailRow(label: 'Refund Status', value: row.refundStatus),
                  _DetailRow(label: 'Returned', value: row.returned),
                  _DetailRow(
                      label: 'Amount Refunded',
                      value: row.amountRefunded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Skeletonizer(
        enabled: true,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: 8,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppTheme.borderLight),
          itemBuilder: (context, index) => _SalesReturnsTableRow(
            row: _SalesReturnRow.skeleton(),
            checked: false,
            onCheckChanged: null,
            onTap: null,
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.errorRed)),
      );
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Text('No sales returns found',
            style:
                TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _filteredRows.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppTheme.borderLight),
      itemBuilder: (context, index) => _SalesReturnsTableRow(
        row: _filteredRows[index],
        checked: _selectedIndices.contains(index),
        onCheckChanged: (v) => _toggleRow(index, v),
        onTap: () => setState(() => _detailIndex = index),
      ),
    );
  }
}

// ─── Toolbar ─────────────────────────────────────────────────────────────────

class _SalesReturnsToolbar extends StatelessWidget {
  const _SalesReturnsToolbar({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            'All Sales Returns',
            style: AppTheme.pageTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          ZButton.primary(
            label: 'New',
            icon: LucideIcons.plus,
            onPressed: () => context.go(AppRoutes.salesReturnsCreate),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              onPressed: onRefresh,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _SalesReturnsTableHeader extends StatelessWidget {
  const _SalesReturnsTableHeader({
    required this.allSelected,
    required this.someSelected,
    required this.onSelectAll,
  });

  final bool allSelected;
  final bool someSelected;
  final ValueChanged<bool?> onSelectAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppTheme.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: someSelected ? null : allSelected,
              tristate: true,
              onChanged: onSelectAll,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 16),
          const _HeaderCell(width: 140, label: 'DATE'),
          const _HeaderCell(width: 140, label: 'RMA#'),
          const _HeaderCell(width: 160, label: 'SALES ORDER#'),
          const _HeaderCell(width: 180, label: 'CUSTOMER NAME'),
          const _HeaderCell(width: 140, label: 'STATUS'),
          const _HeaderCell(width: 140, label: 'RECEIVE STATUS'),
          const _HeaderCell(width: 140, label: 'REFUND STATUS'),
          const _HeaderCell(width: 120, label: 'RETURNED'),
          const _HeaderCell(width: 120, label: 'AMOUNT REFUNDED'),
        ],
      ),
    );
  }
}

// ─── Table Row ────────────────────────────────────────────────────────────────

class _SalesReturnsTableRow extends StatefulWidget {
  const _SalesReturnsTableRow({
    required this.row,
    required this.checked,
    required this.onCheckChanged,
    required this.onTap,
  });

  final _SalesReturnRow row;
  final bool checked;
  final ValueChanged<bool?>? onCheckChanged;
  final VoidCallback? onTap;

  @override
  State<_SalesReturnsTableRow> createState() =>
      _SalesReturnsTableRowState();
}

class _SalesReturnsTableRowState extends State<_SalesReturnsTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 48,
          color: widget.checked
              ? AppTheme.primaryBlue.withValues(alpha: 0.04)
              : _hovered
                  ? AppTheme.primaryBlue.withValues(alpha: 0.02)
                  : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: widget.checked,
                  onChanged: widget.onCheckChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: AppTheme.primaryBlue,
                  side: const BorderSide(
                      color: AppTheme.borderLight, width: 1.5),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 16),
              _BodyCell(width: 140, child: _BodyText(widget.row.date)),
              _BodyCell(
                width: 140,
                child: _BodyText(
                  widget.row.rmaNumber,
                  color: AppTheme.primaryBlueDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _BodyCell(
                  width: 160,
                  child: _BodyText(widget.row.salesOrderNumber)),
              _BodyCell(
                  width: 180,
                  child: _BodyText(widget.row.customerName)),
              _BodyCell(
                width: 140,
                child: _BodyText(
                  widget.row.status,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _BodyCell(
                  width: 140,
                  child: _BodyText(widget.row.receiveStatus)),
              _BodyCell(
                  width: 140,
                  child: _BodyText(widget.row.refundStatus)),
              _BodyCell(
                  width: 120, child: _BodyText(widget.row.returned)),
              _BodyCell(
                  width: 120,
                  child: _BodyText(widget.row.amountRefunded)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Compact list item (split view left side) ─────────────────────────────────

class _SrCompactItem extends StatefulWidget {
  const _SrCompactItem({
    required this.row,
    required this.selected,
    required this.checked,
    required this.onCheckChanged,
    required this.onTap,
  });
  final _SalesReturnRow row;
  final bool selected;
  final bool checked;
  final ValueChanged<bool?> onCheckChanged;
  final VoidCallback onTap;

  @override
  State<_SrCompactItem> createState() => _SrCompactItemState();
}

class _SrCompactItemState extends State<_SrCompactItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppTheme.primaryBlue.withValues(alpha: 0.06)
        : _hovered
            ? AppTheme.primaryBlue.withValues(alpha: 0.04)
            : AppTheme.backgroundColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 80,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: widget.checked,
                  onChanged: widget.onCheckChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: AppTheme.primaryBlue,
                  side: const BorderSide(
                      color: AppTheme.borderLight, width: 1.5),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.row.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          widget.row.returned,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.row.rmaNumber} • ${widget.row.date}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.row.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _statusColor(widget.row.status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return AppTheme.successGreen;
      case 'DRAFT':
        return AppTheme.textSecondary;
      case 'VOID':
        return AppTheme.errorRed;
      default:
        return AppTheme.primaryBlue;
    }
  }
}

// ─── Bulk action button ───────────────────────────────────────────────────────

class _SrBulkActionButton extends StatefulWidget {
  const _SrBulkActionButton({
    this.label,
    this.icon,
    this.trailingIcon,
    required this.onTap,
  });
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  @override
  State<_SrBulkActionButton> createState() => _SrBulkActionButtonState();
}

class _SrBulkActionButtonState extends State<_SrBulkActionButton> {
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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                Icon(widget.trailingIcon,
                    size: 14, color: AppTheme.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Menu option ─────────────────────────────────────────────────────────────

class _SrMenuOption extends StatefulWidget {
  const _SrMenuOption({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_SrMenuOption> createState() => _SrMenuOptionState();
}

class _SrMenuOptionState extends State<_SrMenuOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              color:
                  _hovered ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Detail panel helpers ─────────────────────────────────────────────────────

class _DetailActionBtn extends StatelessWidget {
  const _DetailActionBtn({
    required this.icon,
    this.label,
    required this.onTap,
  });
  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(label!,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailActionDivider extends StatelessWidget {
  const _DetailActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppTheme.borderLight,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── Shared cell widgets ──────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.width, required this.label});
  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
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
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({required this.width, required this.child});
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(
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
      style:
          TextStyle(fontSize: 13, fontWeight: fontWeight, color: color),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _SalesReturnRow {
  const _SalesReturnRow({
    required this.id,
    required this.date,
    required this.rmaNumber,
    required this.salesOrderNumber,
    required this.customerName,
    required this.status,
    required this.receiveStatus,
    required this.refundStatus,
    required this.returned,
    required this.amountRefunded,
  });

  factory _SalesReturnRow.fromJson(Map<String, dynamic> json) {
    final customer =
        (json['customer'] as Map<String, dynamic>?) ?? const {};
    final displayName =
        (customer['display_name'] ?? '').toString().trim();
    final firstName =
        (customer['first_name'] ?? '').toString().trim();
    final lastName = (customer['last_name'] ?? '').toString().trim();
    final companyName =
        (customer['company_name'] ?? '').toString().trim();
    final customerName = displayName.isNotEmpty
        ? displayName
        : companyName.isNotEmpty
            ? companyName
            : '$firstName $lastName'.trim();

    final returnDateRaw = (json['return_date'] ?? '').toString();
    DateTime? returnDate;
    if (returnDateRaw.isNotEmpty) {
      returnDate = DateTime.tryParse(returnDateRaw);
    }
    final date = returnDate != null
        ? DateFormat('dd-MM-yyyy').format(returnDate)
        : '-';

    final status = (json['status'] ?? '-').toString().toUpperCase();
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    double returnedTotal = 0;
    for (final row in items) {
      final returnQty =
          (row['return_qty'] as num?)?.toDouble() ?? 0;
      final receivableQty =
          (row['receivable_qty'] as num?)?.toDouble() ?? 0;
      final creditOnlyQty =
          (row['credit_only_qty'] as num?)?.toDouble() ?? 0;
      returnedTotal +=
          returnQty > 0 ? returnQty : (receivableQty + creditOnlyQty);
    }

    return _SalesReturnRow(
      id: (json['id'] ?? '').toString(),
      date: date,
      rmaNumber: (json['rma_number'] ?? '-').toString(),
      salesOrderNumber:
          (json['reference_number'] ?? '-').toString(),
      customerName:
          customerName.isEmpty ? '-' : customerName,
      status: status,
      receiveStatus: status == 'APPROVED' ? 'RECEIVED' : '-',
      refundStatus: '-',
      returned: returnedTotal.toStringAsFixed(2),
      amountRefunded: '-',
    );
  }

  factory _SalesReturnRow.skeleton() {
    return const _SalesReturnRow(
      id: 'skeleton',
      date: '15-05-2026',
      rmaNumber: 'RMA-00000',
      salesOrderNumber: 'SO-00000',
      customerName: 'Customer Name',
      status: 'DRAFT',
      receiveStatus: 'RECEIVED',
      refundStatus: '-',
      returned: '0.00',
      amountRefunded: '0.00',
    );
  }

  final String id;
  final String date;
  final String rmaNumber;
  final String salesOrderNumber;
  final String customerName;
  final String status;
  final String receiveStatus;
  final String refundStatus;
  final String returned;
  final String amountRefunded;
}
