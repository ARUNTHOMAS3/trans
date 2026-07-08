// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert' show utf8;
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_header_menu.dart';
import 'package:zerpai_erp/shared/widgets/tables/col_resize_handle.dart';
import 'package:zerpai_erp/modules/procurement/purchase_request/presentation/pages/procurement_demand_pool_dialog.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

enum _PrStatus { approved, onHold, awaitingApproval, rejected }

class _PurchaseRequest {
  const _PurchaseRequest({
    required this.requestNumber,
    required this.submitter,
    required this.submittedOn,
    required this.expectedDate,
    required this.status,
    required this.approver,
    required this.assignee,
    required this.amount,
  });

  final String requestNumber;
  final String submitter;
  final String submittedOn;
  final String expectedDate;
  final _PrStatus status;
  final String approver;
  final String assignee;
  final double amount;
}

// ---------------------------------------------------------------------------
// Status helper
// ---------------------------------------------------------------------------

_PrStatus _parsePrStatus(String? raw) => switch ((raw ?? '').toUpperCase()) {
  'APPROVED'          => _PrStatus.approved,
  'ON_HOLD' || 'ONHOLD' => _PrStatus.onHold,
  'AWAITING_APPROVAL' => _PrStatus.awaitingApproval,
  'REJECTED'          => _PrStatus.rejected,
  _                   => _PrStatus.awaitingApproval,
};

String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  try {
    final d = DateTime.parse(raw);
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-${d.year}';
  } catch (_) {
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ProcurementPurchaseRequestsListPage extends ConsumerStatefulWidget {
  const ProcurementPurchaseRequestsListPage({super.key});

  @override
  ConsumerState<ProcurementPurchaseRequestsListPage> createState() =>
      _ProcurementPurchaseRequestsListPageState();
}

class _ProcurementPurchaseRequestsListPageState
    extends ConsumerState<ProcurementPurchaseRequestsListPage> {
  _TabFilter _activeTab = _TabFilter.all;
  _SortField _sortField = _SortField.requestNumber;
  _SortDir _sortDir = _SortDir.descending;
  final Set<int> _selected = {};

  List<_PurchaseRequest> _allRows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchaseRequests();
  }

  Future<void> _loadPurchaseRequests() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('purchase_requests')
          .select('id, request_number, status, expected_date, created_at, '
              'assignee:users!assignee_id(full_name), '
              'purchase_request_items(estimated_amount)')
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _allRows = (response as List<dynamic>).map((json) {
          final map = json as Map<String, dynamic>;
          final items = (map['purchase_request_items'] as List<dynamic>?) ?? [];
          final total = items.fold<double>(
            0,
            (s, i) => s + ((i as Map<String, dynamic>)['estimated_amount'] as num? ?? 0).toDouble(),
          );
          final assigneeMap = map['assignee'] as Map<String, dynamic>?;
          final assigneeName = assigneeMap?['full_name'] as String? ?? '—';
          return _PurchaseRequest(
            requestNumber: map['request_number'] as String? ?? '',
            submitter: 'zabnixprivatelimited',
            submittedOn: _fmtDate(map['created_at'] as String?),
            expectedDate: _fmtDate(map['expected_date'] as String?),
            status: _parsePrStatus(map['status'] as String?),
            approver: 'zabnixprivatelimited',
            assignee: assigneeName,
            amount: total,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load purchase requests', error: e, module: 'PurchaseRequests');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_PurchaseRequest> get _filtered {
    final base = switch (_activeTab) {
      _TabFilter.all => List<_PurchaseRequest>.from(_allRows),
      _TabFilter.awaitingApproval => _allRows
          .where((r) => r.status == _PrStatus.awaitingApproval)
          .toList(),
      _TabFilter.approved =>
        _allRows.where((r) => r.status == _PrStatus.approved).toList(),
      _TabFilter.rejected =>
        _allRows.where((r) => r.status == _PrStatus.rejected).toList(),
      _TabFilter.onHold =>
        _allRows.where((r) => r.status == _PrStatus.onHold).toList(),
      _TabFilter.yetToBeOrdered ||
      _TabFilter.processed ||
      _TabFilter.cancelled =>
        <_PurchaseRequest>[],
    };

    base.sort((a, b) {
      final cmp = switch (_sortField) {
        _SortField.submitter => a.submitter.compareTo(b.submitter),
        _SortField.requestNumber => a.requestNumber.compareTo(b.requestNumber),
        _SortField.expectedDate => a.expectedDate.compareTo(b.expectedDate),
        _SortField.status => a.status.index.compareTo(b.status.index),
        _SortField.approver => a.approver.compareTo(b.approver),
        _SortField.assignee => a.assignee.compareTo(b.assignee),
        _SortField.amount => a.amount.compareTo(b.amount),
      };
      return _sortDir == _SortDir.ascending ? cmp : -cmp;
    });
    return base;
  }

  void _onSort(_SortField field) {
    setState(() {
      if (_sortField == field) {
        _sortDir = _sortDir == _SortDir.ascending
            ? _SortDir.descending
            : _SortDir.ascending;
      } else {
        _sortField = field;
        _sortDir = _SortDir.ascending;
      }
    });



  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'Purchase Requests',
      useHorizontalPadding: false,
      titlePadding: const EdgeInsets.only(left: 16),
      actions: _selected.isEmpty
          ? [
              _DemandPoolButton(onRefresh: _onRefresh),
              const SizedBox(width: 8),
              _ViewRequestedItemsButton(),
              const SizedBox(width: 8),
              const _SettingsMenu(),
              const SizedBox(width: 4),
              _MoreOptionsMenu(
                activeSortField: _sortField,
                onSortChanged: _onSort,
                onRefresh: _onRefresh,
                onExport: () => _showExportDialog(context, rows: _filtered),
              ),
            ]
          : [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_selected.isNotEmpty)
            _SelectionBar(
              count: _selected.length,
              onExport: () => _showExportDialog(context),
              onClear: () => setState(() => _selected.clear()),
            )
          else
            _TabBar(
              active: _activeTab,
              onChanged: (tab) => setState(() {
                _activeTab = tab;
                _selected.clear();
              }),
            ),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
          _RequestsTable(
            rows: _filtered,
            isLoading: _isLoading,
            selected: _selected,
            sortField: _sortField,
            sortDir: _sortDir,
            onSort: _onSort,
            onToggleRow: (i) => setState(() {
              if (_selected.contains(i)) {
                _selected.remove(i);
              } else {
                _selected.add(i);
              }
            }),
            onToggleAll: () => setState(() {
              if (_selected.length == _filtered.length) {
                _selected.clear();
              } else {
                _selected
                  ..clear()
                  ..addAll(List.generate(_filtered.length, (i) => i));
              }
            }),
          ),
        ],
      ),
    );
  }

  void _onRefresh() {
    setState(() {
      _activeTab = _TabFilter.all;
      _sortField = _SortField.requestNumber;
      _sortDir = _SortDir.descending;
      _selected.clear();
      _isLoading = true;
      _allRows = [];
    });
    _loadPurchaseRequests();
  }

  void _showExportDialog(BuildContext context, {List<_PurchaseRequest>? rows}) {
    final exportRows =
        rows ?? _selected.map((i) => _filtered[i]).toList();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _ExportDialog(rows: exportRows),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort + Tab filter enums
// ---------------------------------------------------------------------------

enum _SortField {
  submitter,
  requestNumber,
  expectedDate,
  status,
  approver,
  assignee,
  amount,
}

enum _SortDir { ascending, descending }

enum _TabFilter {
  all,
  awaitingApproval,
  approved,
  rejected,
  onHold,
  yetToBeOrdered,
  processed,
  cancelled,
}

// ── Selection bar (replaces tab bar when rows are checked) ───────────────────

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.onExport,
    required this.onClear,
  });

  final int count;
  final VoidCallback onExport;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            '$count purchase request${count == 1 ? '' : 's'} selected',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onExport,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.successGreen,
              backgroundColor: const Color(0xFFF3F4F6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Export'),
          ),
          const Spacer(),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Export dialog ─────────────────────────────────────────────────────────────

enum _ExportFormat { csv, xls, xlsx }

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.rows});
  final List<_PurchaseRequest> rows;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  _ExportFormat _format = _ExportFormat.csv;
  bool _includePii = false;

  static String _statusLabel(_PrStatus s) => switch (s) {
    _PrStatus.approved        => 'Approved',
    _PrStatus.onHold          => 'On Hold',
    _PrStatus.awaitingApproval => 'Draft',
    _PrStatus.rejected        => 'Rejected',
  };

  String _buildCsv() {
    final buf = StringBuffer();
    buf.writeln('REQUEST#,SUBMITTER,SUBMITTED ON,EXPECTED DATE,STATUS,APPROVER,ASSIGNEE,AMOUNT');
    for (final r in widget.rows) {
      final sub = _includePii ? r.submitter : '***';
      final apr = _includePii ? r.approver  : '***';
      final asn = _includePii ? r.assignee  : '***';
      buf.writeln(
        '"${r.requestNumber}","$sub","${r.submittedOn}","${r.expectedDate}",'
        '"${_statusLabel(r.status)}","$apr","$asn","${r.amount.toStringAsFixed(2)}"',
      );
    }
    return buf.toString();
  }

  String _buildXml() {
    final buf = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"')
      ..writeln('  xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">')
      ..writeln('  <Worksheet ss:Name="Purchase Requests">')
      ..writeln('    <Table>');

    void cell(String type, String value) =>
        buf.writeln('        <Cell><Data ss:Type="$type">$value</Data></Cell>');

    // Header
    buf.writeln('      <Row>');
    for (final h in ['REQUEST#', 'SUBMITTER', 'SUBMITTED ON', 'EXPECTED DATE',
                      'STATUS', 'APPROVER', 'ASSIGNEE', 'AMOUNT']) {
      cell('String', h);
    }
    buf.writeln('      </Row>');

    // Data
    for (final r in widget.rows) {
      final sub = _includePii ? r.submitter : '***';
      final apr = _includePii ? r.approver  : '***';
      final asn = _includePii ? r.assignee  : '***';
      buf.writeln('      <Row>');
      cell('String', r.requestNumber);
      cell('String', sub);
      cell('String', r.submittedOn);
      cell('String', r.expectedDate);
      cell('String', _statusLabel(r.status));
      cell('String', apr);
      cell('String', asn);
      cell('Number', r.amount.toStringAsFixed(2));
      buf.writeln('      </Row>');
    }

    buf
      ..writeln('    </Table>')
      ..writeln('  </Worksheet>')
      ..writeln('</Workbook>');
    return buf.toString();
  }

  void _doExport() {
    final String content;
    final String filename;
    final String mimeType;

    switch (_format) {
      case _ExportFormat.csv:
        content  = _buildCsv();
        filename = 'purchase_requests.csv';
        mimeType = 'text/csv;charset=utf-8;';
      case _ExportFormat.xls:
        content  = _buildXml();
        filename = 'purchase_requests.xls';
        mimeType = 'application/vnd.ms-excel';
      case _ExportFormat.xlsx:
        content  = _buildXml();
        filename = 'purchase_requests.xlsx';
        mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }

    final blob   = html.Blob([utf8.encode(content)], mimeType);
    final url    = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  const Text(
                    'Export',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(LucideIcons.x,
                          size: 18, color: AppTheme.errorRed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Export as label (required — red)
              const Row(
                children: [
                  Text(
                    'Export as',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Radio options
              _RadioOption(
                label: 'CSV (Comma Separated Value)',
                value: _ExportFormat.csv,
                groupValue: _format,
                onChanged: (v) => setState(() => _format = v!),
              ),
              const SizedBox(height: 8),
              _RadioOption(
                label: 'XLS (Microsoft Excel 1997-2004 Compatible)',
                value: _ExportFormat.xls,
                groupValue: _format,
                onChanged: (v) => setState(() => _format = v!),
              ),
              const SizedBox(height: 8),
              _RadioOption(
                label: 'XLSX (Microsoft Excel)',
                value: _ExportFormat.xlsx,
                groupValue: _format,
                onChanged: (v) => setState(() => _format = v!),
              ),
              const SizedBox(height: 20),
              // PII checkbox
              _ExportCheckbox(
                value: _includePii,
                label:
                    'Include Sensitive Personally Identifiable Information (PII) while exporting.',
                onChanged: (v) => setState(() => _includePii = v ?? false),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppTheme.borderColor),
              const SizedBox(height: 16),
              // Footer
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _doExport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Export'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textBody,
                      side: const BorderSide(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final _ExportFormat value;
  final _ExportFormat groupValue;
  final ValueChanged<_ExportFormat?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Radio<_ExportFormat>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: AppTheme.primaryBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportCheckbox extends StatelessWidget {
  const _ExportCheckbox({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryBlue,
            side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatefulWidget {
  const _TabBar({required this.active, required this.onChanged});

  final _TabFilter active;
  final ValueChanged<_TabFilter> onChanged;

  @override
  State<_TabBar> createState() => _TabBarState();
}

class _TabBarState extends State<_TabBar> {
  final _dotsLink = LayerLink();
  final _dotsKey = GlobalKey();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _toggle(BuildContext context) {
    if (_overlay != null) {
      _overlay!.remove();
      _overlay = null;
      setState(() {});
      return;
    }
    final box =
        _dotsKey.currentContext!.findRenderObject()! as RenderBox;
    final h = box.size.height;

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _overlay?.remove();
                _overlay = null;
                if (mounted) setState(() {});
              },
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _dotsLink,
            showWhenUnlinked: false,
            offset: Offset(0, h + 4),
            child: Align(
              alignment: Alignment.topLeft,
              child: _TabDropdownPanel(
                active: widget.active,
                onSelect: (f) {
                  _overlay?.remove();
                  _overlay = null;
                  if (mounted) setState(() {});
                  widget.onChanged(f);
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  static const _kOverflowFilters = {
    _TabFilter.rejected,
    _TabFilter.onHold,
    _TabFilter.yetToBeOrdered,
    _TabFilter.processed,
    _TabFilter.cancelled,
  };

  static String _labelFor(_TabFilter f) => switch (f) {
    _TabFilter.approved        => 'Approved',
    _TabFilter.rejected        => 'Rejected',
    _TabFilter.onHold          => 'On Hold',
    _TabFilter.yetToBeOrdered  => 'Yet To Be Ordered',
    _TabFilter.processed       => 'Processed',
    _TabFilter.cancelled       => 'Cancelled',
    _                          => 'Approved',
  };

  @override
  Widget build(BuildContext context) {
    // 3rd tab slot: show the active overflow tab if one is selected,
    // otherwise fall back to "Approved".
    final thirdFilter = _kOverflowFilters.contains(widget.active)
        ? widget.active
        : _TabFilter.approved;

    return Row(
      children: [
        _Tab(
          label: 'All',
          isActive: widget.active == _TabFilter.all,
          onTap: () => widget.onChanged(_TabFilter.all),
        ),
        _Tab(
          label: 'Draft',
          isActive: widget.active == _TabFilter.awaitingApproval,
          onTap: () => widget.onChanged(_TabFilter.awaitingApproval),
        ),
        _Tab(
          label: _labelFor(thirdFilter),
          isActive: widget.active == thirdFilter,
          onTap: () => widget.onChanged(thirdFilter),
        ),
        const SizedBox(width: 8),
        CompositedTransformTarget(
          link: _dotsLink,
          child: GestureDetector(
            key: _dotsKey,
            onTap: () => _toggle(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _overlay != null
                    ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                    : AppTheme.bgDisabled,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '...',
                style: TextStyle(
                  fontSize: 13,
                  color: _overlay != null
                      ? AppTheme.primaryBlue
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab dropdown panel ────────────────────────────────────────────────────────

class _TabDropdownPanel extends StatefulWidget {
  const _TabDropdownPanel({
    required this.active,
    required this.onSelect,
  });

  final _TabFilter active;
  final ValueChanged<_TabFilter> onSelect;

  @override
  State<_TabDropdownPanel> createState() => _TabDropdownPanelState();
}

class _TabDropdownPanelState extends State<_TabDropdownPanel> {
  _TabFilter? _hovered;

  static const _kItems = [
    (_TabFilter.all, 'All'),
    (_TabFilter.awaitingApproval, 'Draft'),
    (_TabFilter.approved, 'Approved'),
    (_TabFilter.rejected, 'Rejected'),
    (_TabFilter.onHold, 'On Hold'),
    (_TabFilter.yetToBeOrdered, 'Yet To Be Ordered'),
    (_TabFilter.processed, 'Processed'),
    (_TabFilter.cancelled, 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'DEFAULT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            // Filter items
            ..._kItems.map((entry) {
              final (filter, label) = entry;
              final isActive = filter == widget.active;
              final isHovered = _hovered == filter;

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hovered = filter),
                onExit: (_) => setState(() => _hovered = null),
                child: GestureDetector(
                  onTap: () => widget.onSelect(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: double.infinity,
                    color: isActive
                        ? const Color(0xFFF0F4FF)
                        : isHovered
                            ? AppTheme.infoBlue
                            : Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: isActive
                            ? AppTheme.primaryBlue
                            : isHovered
                                ? Colors.white
                                : AppTheme.textPrimary,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.successGreen : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppTheme.successGreen : AppTheme.textBody,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Table
// ---------------------------------------------------------------------------

class _RequestsTable extends StatefulWidget {
  const _RequestsTable({
    required this.rows,
    required this.isLoading,
    required this.selected,
    required this.sortField,
    required this.sortDir,
    required this.onSort,
    required this.onToggleRow,
    required this.onToggleAll,
  });

  final List<_PurchaseRequest> rows;
  final bool isLoading;
  final Set<int> selected;
  final _SortField sortField;
  final _SortDir sortDir;
  final ValueChanged<_SortField> onSort;
  final ValueChanged<int> onToggleRow;
  final VoidCallback onToggleAll;

  @override
  State<_RequestsTable> createState() => _RequestsTableState();
}

class _RequestsTableState extends State<_RequestsTable> {
  bool _wrapText = false;

  static const _kSubmitter = 'submitter';
  static const _kRequest   = 'request';
  static const _kDate      = 'date';
  static const _kStatus    = 'status';
  static const _kApprover  = 'approver';
  static const _kAssignee  = 'assignee';

  final Map<String, double> _colWidths = {
    _kSubmitter: 200,
    _kRequest:   130,
    _kDate:      140,
    _kStatus:    120,
    _kApprover:  180,
    _kAssignee:  200,
  };

  void _onResize(String col, double delta) {
    setState(() {
      _colWidths[col] = (_colWidths[col]! + delta).clamp(60, 500);
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = widget.rows.isNotEmpty && widget.selected.length == widget.rows.length;
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header — always visible
        _TableHeader(
          allSelected: allSelected,
          onToggleAll: widget.onToggleAll,
          sortField: widget.sortField,
          sortDir: widget.sortDir,
          onSort: widget.onSort,
          wrapText: _wrapText,
          onWrapChange: (v) => setState(() => _wrapText = v),
          colWidths: _colWidths,
          onResize: _onResize,
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        // Rows area
        if (widget.isLoading)
          const TableSkeleton(rows: 10, columns: 7, showHeader: false)
        else if (widget.rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'No purchase requests found.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            ),
          )
        else
          ...List.generate(widget.rows.length, (i) {
            final pr = widget.rows[i];
            return Column(
              children: [
                _TableRow(
                  pr: pr,
                  isSelected: widget.selected.contains(i),
                  onToggle: () => widget.onToggleRow(i),
                  orgSystemId: orgSystemId,
                  wrapText: _wrapText,
                  colWidths: _colWidths,
                ),
                if (i < widget.rows.length - 1)
                  const Divider(height: 1, color: AppTheme.borderColor),
              ],
            );
          }),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.allSelected,
    required this.onToggleAll,
    required this.sortField,
    required this.sortDir,
    required this.onSort,
    required this.wrapText,
    required this.onWrapChange,
    required this.colWidths,
    required this.onResize,
  });

  final bool allSelected;
  final VoidCallback onToggleAll;
  final _SortField sortField;
  final _SortDir sortDir;
  final ValueChanged<_SortField> onSort;
  final bool wrapText;
  final ValueChanged<bool> onWrapChange;
  final Map<String, double> colWidths;
  final void Function(String col, double delta) onResize;

  Widget _resizableCol(
    String key,
    Widget header,
    void Function(String, double) onResizeCb,
  ) {
    return SizedBox(
      width: colWidths[key],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: header,
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ColResizeHandle(onResize: (d) => onResizeCb(key, d)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _SortableHeader sortCol(String label, _SortField field, {TextAlign textAlign = TextAlign.left}) =>
        _SortableHeader(label: label, field: field, activeField: sortField, dir: sortDir, onSort: onSort, textAlign: textAlign);

    return ClipRect(
    child: Container(
      height: 40,
      color: AppTheme.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ZTableHeaderMenu(wrapText: wrapText, onWrapChange: onWrapChange, onCustomize: () {}),
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            child: Checkbox(
              value: allSelected,
              onChanged: (_) => onToggleAll(),
              activeColor: AppTheme.primaryBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          _resizableCol(_RequestsTableState._kSubmitter,  sortCol('SUBMITTER',      _SortField.submitter),      onResize),
          _resizableCol(_RequestsTableState._kRequest,    sortCol('REQUEST#',        _SortField.requestNumber),  onResize),
          _resizableCol(_RequestsTableState._kDate,       sortCol('EXPECTED DATE',   _SortField.expectedDate),   onResize),
          _resizableCol(_RequestsTableState._kStatus,     sortCol('STATUS',          _SortField.status),         onResize),
          _resizableCol(_RequestsTableState._kApprover,   sortCol('APPROVER',        _SortField.approver),       onResize),
          _resizableCol(_RequestsTableState._kAssignee,   sortCol('ASSIGNEE',        _SortField.assignee),       onResize),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: sortCol('AMOUNT', _SortField.amount),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _SortableHeader extends StatefulWidget {
  const _SortableHeader({
    required this.label,
    required this.field,
    required this.activeField,
    required this.dir,
    required this.onSort,
    this.textAlign = TextAlign.left,
  });

  final String label;
  final _SortField field;
  final _SortField activeField;
  final _SortDir dir;
  final ValueChanged<_SortField> onSort;
  final TextAlign textAlign;

  @override
  State<_SortableHeader> createState() => _SortableHeaderState();
}

class _SortableHeaderState extends State<_SortableHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.field == widget.activeField;
    final IconData sortIcon = isActive
        ? (widget.dir == _SortDir.ascending
            ? LucideIcons.arrowUp
            : LucideIcons.arrowDown)
        : LucideIcons.chevronsUpDown;
    final Color labelColor =
        isActive ? AppTheme.primaryBlue : AppTheme.textMuted;
    final Color iconColor = isActive
        ? AppTheme.primaryBlue
        : _hovered
            ? AppTheme.textBody
            : AppTheme.textMuted;

    final row = Row(
      children: [
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: labelColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Icon(sortIcon, size: 10, color: iconColor),
      ],
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onSort(widget.field),
        child: widget.textAlign == TextAlign.right
            ? Align(alignment: Alignment.centerRight, child: row)
            : row,
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  const _TableRow({
    required this.pr,
    required this.isSelected,
    required this.onToggle,
    required this.orgSystemId,
    required this.wrapText,
    required this.colWidths,
  });

  final _PurchaseRequest pr;
  final bool isSelected;
  final VoidCallback onToggle;
  final String orgSystemId;
  final bool wrapText;
  final Map<String, double> colWidths;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final pr = widget.pr;
    final isSelected = widget.isSelected;

    Color rowColor;
    if (isSelected) {
      rowColor = AppTheme.primaryBlue.withValues(alpha: 0.04);
    } else if (_hovered) {
      rowColor = AppTheme.bgDisabled;
    } else {
      rowColor = Colors.white;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          context.goNamed(
            AppRoutes.procurementPurchaseRequestOverview,
            pathParameters: {
              'orgSystemId': widget.orgSystemId,
              'id': widget.pr.requestNumber,
            },
          );
        },
        child: ClipRect(
        child: Container(
        color: rowColor,
        height: widget.wrapText ? null : 48,
        constraints: widget.wrapText ? const BoxConstraints(minHeight: 48) : null,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: widget.wrapText ? 10 : 0),
        child: Row(
        crossAxisAlignment: widget.wrapText ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          // Placeholder matching header's ZTableHeaderMenu(28) + gap(4)
          const SizedBox(width: 32),
          SizedBox(
            width: 32,
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => widget.onToggle(),
              activeColor: AppTheme.primaryBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          // Submitter
          SizedBox(
            width: widget.colWidths[_RequestsTableState._kSubmitter],
            child: _UserCell(
              name: pr.submitter,
              subtitle: 'on : ${pr.submittedOn}',
              wrapText: widget.wrapText,
            ),
          ),
          // Request#
          SizedBox(
            width: widget.colWidths[_RequestsTableState._kRequest],
            child: Text(
              pr.requestNumber,
              maxLines: widget.wrapText ? null : 1,
              overflow: widget.wrapText ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primaryBlue),
            ),
          ),
          // Expected date
          SizedBox(
            width: widget.colWidths[_RequestsTableState._kDate],
            child: Text(
              pr.expectedDate,
              maxLines: widget.wrapText ? null : 1,
              overflow: widget.wrapText ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
            ),
          ),
          // Status
          SizedBox(
            width: widget.colWidths[_RequestsTableState._kStatus],
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusBadge(status: pr.status),
            ),
          ),
          // Approver
          SizedBox(
            width: widget.colWidths[_RequestsTableState._kApprover],
            child: _UserCell(name: pr.approver, wrapText: widget.wrapText),
          ),
          // Assignee
          SizedBox(
            width: widget.colWidths[_RequestsTableState._kAssignee],
            child: _UserCell(name: pr.assignee, wrapText: widget.wrapText),
          ),
          // Amount
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '₹${_formatAmount(pr.amount)}',
                maxLines: widget.wrapText ? null : 1,
                overflow: widget.wrapText ? TextOverflow.visible : TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textBody),
              ),
            ),
          ),
        ],
      ),
        ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      final parts = amount.toStringAsFixed(2).split('.');
      final intPart = parts[0];
      final decPart = parts[1];
      final buf = StringBuffer();
      int count = 0;
      for (int i = intPart.length - 1; i >= 0; i--) {
        buf.write(intPart[i]);
        count++;
        if (count == 3 && i != 0) {
          buf.write(',');
          count = 0;
        }
      }
      return '${buf.toString().split('').reversed.join()}.$decPart';
    }
    return amount.toStringAsFixed(2);
  }
}

// ---------------------------------------------------------------------------
// Reusable cells
// ---------------------------------------------------------------------------

class _UserCell extends StatelessWidget {
  const _UserCell({required this.name, this.subtitle, this.wrapText = false});

  final String name;
  final String? subtitle;
  final bool wrapText;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? '—' : name;
    if (subtitle == null) {
      return Text(
        displayName,
        maxLines: wrapText ? null : 1,
        overflow: wrapText ? TextOverflow.visible : TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, color: AppTheme.textBody, fontWeight: FontWeight.w500),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayName,
          maxLines: wrapText ? null : 1,
          overflow: wrapText ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppTheme.textBody, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle!,
          maxLines: wrapText ? null : 1,
          overflow: wrapText ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _PrStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      _PrStatus.approved => 'APPROVED',
      _PrStatus.onHold => 'ON HOLD',
      _PrStatus.awaitingApproval => 'DRAFT',
      _PrStatus.rejected => 'REJECTED',
    };

    final textColor = switch (status) {
      _PrStatus.approved => AppTheme.successTextDark,
      _PrStatus.onHold => AppTheme.warningTextDark,
      _PrStatus.awaitingApproval => AppTheme.infoTextDark,
      _PrStatus.rejected => AppTheme.errorTextDark,
    };

    final bgColor = switch (status) {
      _PrStatus.approved => AppTheme.successBg,
      _PrStatus.onHold => AppTheme.warningBg,
      _PrStatus.awaitingApproval => AppTheme.infoBg,
      _PrStatus.rejected => AppTheme.errorBg,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action widgets
// ---------------------------------------------------------------------------

class _DemandPoolButton extends StatefulWidget {
  const _DemandPoolButton({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  State<_DemandPoolButton> createState() => _DemandPoolButtonState();
}

class _DemandPoolButtonState extends State<_DemandPoolButton> {
  bool _saving = false;

  Future<void> _onTap() async {
    final payload = await showDemandPoolDialog(context);
    if (payload == null || payload.lineItems.isEmpty) return;
    if (!mounted) return;

    setState(() => _saving = true);
    try {
      final supabase = Supabase.instance.client;

      // Auto-generate request number
      final countRes = await supabase
          .from('purchase_requests')
          .select('request_number')
          .order('created_at', ascending: false)
          .limit(1);
      int nextNum = 1;
      if ((countRes as List<dynamic>).isNotEmpty) {
        final last = countRes.first['request_number'] as String? ?? '';
        final m = RegExp(r'(\d+)$').firstMatch(last);
        if (m != null) nextNum = int.parse(m.group(1)!) + 1;
      }
      final requestNumber = 'PR-${nextNum.toString().padLeft(5, '0')}';

      // Entity id from first line item
      final entityId = payload.lineItems
          .firstWhere((i) => i.entityId.isNotEmpty,
              orElse: () => payload.lineItems.first)
          .entityId;

      // Insert purchase_requests header
      // Verify assigneeId exists in the Supabase users table.
      // allUsersProvider comes from the backend API and may return different UUIDs.
      String? validAssigneeId;
      if (payload.assigneeId != null) {
        final check = await supabase
            .from('users')
            .select('id')
            .eq('id', payload.assigneeId!)
            .maybeSingle();
        if (check != null) validAssigneeId = payload.assigneeId;
      }

      final prRes = await supabase
          .from('purchase_requests')
          .insert({
            'entity_id': entityId,
            'request_number': requestNumber,
            'status': 'OPEN',
            if (payload.expectedDate != null)
              'expected_date': payload.expectedDate!.toIso8601String().substring(0, 10),
            if (validAssigneeId != null)
              'assignee_id': validAssigneeId,
          })
          .select('id')
          .single();
      final prId = prRes['id'] as String;

      // Fetch cost_price for every product so estimated_rate + estimated_amount are real
      final productIds = payload.lineItems
          .where((i) => i.productId.isNotEmpty)
          .map((i) => i.productId)
          .toSet()
          .toList();
      final Map<String, double> costMap = {};
      if (productIds.isNotEmpty) {
        final pricesRes = await supabase
            .from('products')
            .select('id, cost_price')
            .inFilter('id', productIds);
        for (final row in pricesRes as List<dynamic>) {
          final m = row as Map<String, dynamic>;
          final id = m['id'] as String?;
          final price = (m['cost_price'] as num?)?.toDouble() ?? 0.0;
          if (id != null) costMap[id] = price;
        }
      }

      // Insert line items with real cost_price
      final itemInserts = payload.lineItems
          .where((i) => i.productId.isNotEmpty)
          .map((i) {
            final rate = costMap[i.productId] ?? 0.0;
            final amount = i.reqQty * rate;
            return {
              'purchase_request_id': prId,
              'product_id': i.productId,
              if (i.vendorId != null) 'preferred_vendor_id': i.vendorId,
              'required_qty': i.reqQty,
              'planned_qty': i.plannedQty,
              'pending_qty': i.pendingQty,
              'estimated_rate': rate,
              'estimated_amount': amount,
              'line_status': 'PENDING',
            };
          })
          .toList();
      if (itemInserts.isNotEmpty) {
        await supabase.from('purchase_request_items').insert(itemInserts);
      }

      // Mark demand_pool rows as PR_CREATED and link them to this PR
      // so the edit → "Save & Send to Approve" flow can find them by purchase_request_id.
      final dpIds = payload.lineItems
          .expand((i) => i.demandPoolIds)
          .toSet()
          .toList();
      if (dpIds.isNotEmpty) {
        await supabase
            .from('demand_pool')
            .update({
              'status': 'PR_CREATED',
              'purchase_request_id': prId,
            })
            .inFilter('id', dpIds);
      }

      if (!mounted) return;
      widget.onRefresh();
    } catch (e) {
      AppLogger.error('Failed to save purchase request from demand pool',
          error: e, module: 'PRReport');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _saving ? null : _onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_saving)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
              )
            else
              const Icon(LucideIcons.layers, size: 16, color: AppTheme.primaryBlue),
            const SizedBox(width: 6),
            const Text(
              'Demand Pool',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewRequestedItemsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.procurementRequestedItems),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              LucideIcons.shoppingBag,
              size: 16,
              color: AppTheme.primaryBlue,
            ),
            SizedBox(width: 6),
            Text(
              'View Requested Items',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings menu (gear button)
// ---------------------------------------------------------------------------

class _SettingsMenu extends StatefulWidget {
  const _SettingsMenu();

  @override
  State<_SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<_SettingsMenu> {
  final _layerLink = LayerLink();
  final _buttonKey = GlobalKey();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _toggle(BuildContext context) {
    if (_overlay != null) {
      _overlay!.remove();
      _overlay = null;
      setState(() {});
      return;
    }

    const menuWidth = 180.0;
    final box = _buttonKey.currentContext!.findRenderObject()! as RenderBox;
    final size = box.size;

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _overlay?.remove();
                _overlay = null;
                if (mounted) setState(() {});
              },
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(size.width - menuWidth, size.height + 4),
            child: Align(
              alignment: Alignment.topLeft,
              child: _SettingsDropdownPanel(
                onClose: () {
                  _overlay?.remove();
                  _overlay = null;
                  if (mounted) setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _buttonKey,
        onTap: () => _toggle(context),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            LucideIcons.settings,
            size: 16,
            color: _overlay != null
                ? AppTheme.primaryBlue
                : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SettingsDropdownPanel extends StatelessWidget {
  const _SettingsDropdownPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            _SettingsMenuItem(
              icon: LucideIcons.slidersHorizontal,
              label: 'Preferences',
              onTap: onClose,
            ),
            _SettingsMenuItem(
              icon: LucideIcons.checkCircle,
              label: 'Approvals',
              onTap: onClose,
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _SettingsMenuItem extends StatefulWidget {
  const _SettingsMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SettingsMenuItem> createState() => _SettingsMenuItemState();
}

class _SettingsMenuItemState extends State<_SettingsMenuItem> {
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
          color: _hovered ? AppTheme.infoBlue : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: _hovered ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _hovered ? Colors.white : AppTheme.textBody,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// More options menu (... button)
// ---------------------------------------------------------------------------

class _MoreOptionsMenu extends StatefulWidget {
  const _MoreOptionsMenu({
    required this.activeSortField,
    required this.onSortChanged,
    required this.onRefresh,
    required this.onExport,
  });

  final _SortField activeSortField;
  final ValueChanged<_SortField> onSortChanged;
  final VoidCallback onRefresh;
  final VoidCallback onExport;

  @override
  State<_MoreOptionsMenu> createState() => _MoreOptionsMenuState();
}

class _MoreOptionsMenuState extends State<_MoreOptionsMenu> {
  final MenuController _menuController = MenuController();

  static const List<({_SortField field, String label})> _sortItems = [
    (field: _SortField.submitter, label: 'Submitter'),
    (field: _SortField.requestNumber, label: 'Request#'),
    (field: _SortField.expectedDate, label: 'Expected Date'),
    (field: _SortField.status, label: 'Status'),
    (field: _SortField.approver, label: 'Approver'),
    (field: _SortField.assignee, label: 'Assignee'),
    (field: _SortField.amount, label: 'Amount'),
  ];

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(-160, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        elevation: WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(Colors.black12),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppTheme.borderColor),
          ),
        ),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        minimumSize: WidgetStatePropertyAll(Size(210, 0)),
        maximumSize: WidgetStatePropertyAll(Size(220, double.infinity)),
      ),
      menuChildren: [
        // --- SORT BY section header ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(
            'SORT BY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        // --- Sort options ---
        ..._sortItems.map((item) {
          final isActive = widget.activeSortField == item.field;
          return _SortMenuItem(
            label: item.label,
            isActive: isActive,
            onTap: () {
              widget.onSortChanged(item.field);
              _menuController.close();
            },
          );
        }),
        // --- Divider ---
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Divider(height: 1, color: AppTheme.borderColor),
        ),
        // --- Action items ---
        _ActionMenuItem(
          icon: LucideIcons.refreshCw,
          label: 'Refresh List',
          onTap: () {
            _menuController.close();
            widget.onRefresh();
          },
        ),
        _ActionMenuItem(
          icon: LucideIcons.upload,
          label: 'Export Purchase Requests',
          onTap: () {
            _menuController.close();
            widget.onExport();
          },
        ),
        const SizedBox(height: 6),
      ],
      child: GestureDetector(
        onTap: () {
          if (_menuController.isOpen) {
            _menuController.close();
          } else {
            _menuController.open();
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              LucideIcons.moreHorizontal,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SortMenuItem extends StatefulWidget {
  const _SortMenuItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_SortMenuItem> createState() => _SortMenuItemState();
}

class _SortMenuItemState extends State<_SortMenuItem> {
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
          color: _hovered
              ? AppTheme.infoBlue
              : widget.isActive
                  ? AppTheme.bgHover
                  : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              color: _hovered ? Colors.white : AppTheme.textBody,
              fontWeight:
                  widget.isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionMenuItem extends StatefulWidget {
  const _ActionMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionMenuItem> createState() => _ActionMenuItemState();
}

class _ActionMenuItemState extends State<_ActionMenuItem> {
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
          color: _hovered ? AppTheme.infoBlue : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: _hovered ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _hovered ? Colors.white : AppTheme.textBody,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
