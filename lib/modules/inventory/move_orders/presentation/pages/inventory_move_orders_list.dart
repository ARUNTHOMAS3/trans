import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/shared/widgets/document/document_view_mode_switcher.dart';
import 'package:zerpai_erp/shared/widgets/document/zerpai_document_view.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_search_field.dart';
import 'package:zerpai_erp/shared/widgets/tables/overview_section_card.dart';
import 'package:zerpai_erp/shared/widgets/tables/split_list_detail_layout.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_header_menu.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_more_menu.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class InventoryMoveOrdersListScreen extends StatefulWidget {
  const InventoryMoveOrdersListScreen({super.key, this.id});

  final String? id;

  @override
  State<InventoryMoveOrdersListScreen> createState() =>
      _InventoryMoveOrdersListScreenState();
}

class _MoveOrderRow {
  const _MoveOrderRow({
    required this.id,
    required this.moveOrderNumber,
    required this.moveDate,
    required this.warehouseLabel,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String moveOrderNumber;
  final DateTime? moveDate;
  final String warehouseLabel;
  final String notes;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory _MoveOrderRow.fromJson(
    Map<String, dynamic> json, {
    Map<String, String> warehouseNameById = const <String, String>{},
  }) {
    DateTime? parseDate(dynamic value) {
      final text = (value ?? '').toString().trim();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    bool looksLikeUuid(String value) {
      final uuidPattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      );
      return uuidPattern.hasMatch(value.trim());
    }

    String readString(List<String> keys) {
      for (final key in keys) {
        final value = (json[key] ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final warehouseId = readString(<String>[
      'warehouse_id',
      'warehouseId',
      'source_warehouse_id',
      'from_warehouse_id',
      'location_id',
    ]);
    final explicitWarehouseName = readString(<String>[
      'warehouse_name',
      'warehouseName',
      'source_warehouse_name',
      'from_warehouse_name',
      'location_name',
      'location',
    ]);
    final resolvedWarehouseName = explicitWarehouseName.isNotEmpty
        ? explicitWarehouseName
        : (warehouseNameById[warehouseId] ?? '');
    final warehouseLabel = resolvedWarehouseName.isNotEmpty
        ? resolvedWarehouseName
        : (looksLikeUuid(warehouseId) ? '-' : warehouseId);

    return _MoveOrderRow(
      id: readString(<String>['id', 'move_order_id', 'moveOrderId']),
      moveOrderNumber: readString(<String>[
        'move_order_number',
        'moveOrderNumber',
        'move_order_no',
      ]),
      moveDate: parseDate(json['move_date']),
      warehouseLabel: warehouseLabel,
      notes: (json['notes'] ?? '').toString().trim(),
      status: (json['status'] ?? 'draft').toString().trim(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

bool _looksLikeUuid(String value) {
  final uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  return uuidPattern.hasMatch(value.trim());
}

String _displayText(
  dynamic value, {
  String fallback = '-',
  bool hideUuid = false,
}) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return fallback;
  }
  if (hideUuid && _looksLikeUuid(text)) {
    return fallback;
  }
  return text;
}

String _lookupDisplayName(
  dynamic rawValue,
  Map<String, String> lookup, {
  String fallback = '-',
}) {
  final raw = (rawValue ?? '').toString().trim();
  if (raw.isEmpty) return fallback;
  final resolved = lookup[raw]?.trim() ?? '';
  if (resolved.isNotEmpty) return resolved;
  return _displayText(raw, fallback: fallback, hideUuid: true);
}

String _formatDateValue(String value) {
  final text = value.trim();
  if (text.isEmpty || text == '-') return '-';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  return DateFormat('dd-MM-yyyy').format(parsed);
}

String _formatQuantity(dynamic value) {
  final parsed = double.tryParse((value ?? '').toString().trim());
  if (parsed == null) {
    return _displayText(value, fallback: '0');
  }
  return parsed.toStringAsFixed(2);
}

String _resolveMoveOrderItemDisplayName(Map item) {
  final candidates = <dynamic>[
    item['product_name'],
    item['item_name'],
    item['name'],
    item['description'],
    item['product_code'],
  ];
  for (final candidate in candidates) {
    final value = _displayText(candidate, fallback: '', hideUuid: true);
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '-';
}

class _InventoryMoveOrdersListScreenState
    extends State<InventoryMoveOrdersListScreen> {
  static const String _colDate = 'date';
  static const String _colMoveOrder = 'move_order';
  static const String _colLocation = 'location';
  static const String _colNotes = 'notes';
  static const String _colStatus = 'status';

  static const Map<String, String> _statusLabelMap = <String, String>{
    'all': 'All Move Orders',
    'draft': 'Draft Move Orders',
    'completed': 'Completed Move Orders',
  };

  final ApiClient _apiClient = ApiClient();
  final Set<String> _selectedIds = <String>{};
  final List<ColumnConfig> _allColumns = <ColumnConfig>[];
  final List<String> _visibleColumns = <String>[];

  bool _isLoading = true;
  String? _error;
  bool _shouldWrapText = false;
  String _statusFilter = 'all';
  List<_MoveOrderRow> _rows = const <_MoveOrderRow>[];
  String? _hoveredCompactRowId;

  String get _orgId => GoRouterState.of(context).pathParameters['orgSystemId']!;

  bool get _isDetailOpen => widget.id != null && widget.id!.trim().isNotEmpty;

  double get _tableWidth {
    final columnsWidth = _visibleColumns.fold<double>(0, (sum, id) {
      return sum + _baseColumnWidth(id);
    });
    return 42 + 36 + columnsWidth;
  }

  double _baseColumnWidth(String colId) {
    switch (colId) {
      case _colDate:
        return 124;
      case _colMoveOrder:
        return 160;
      case _colLocation:
        return 240;
      case _colNotes:
        return 340;
      case _colStatus:
        return 140;
      default:
        return 150;
    }
  }

  double _columnWidth(String colId, double scale) {
    return _baseColumnWidth(colId) * scale;
  }

  @override
  void initState() {
    super.initState();
    _initializeColumns();
    _loadColumnSettings();
    _loadRows();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeColumns() {
    _allColumns
      ..clear()
      ..addAll(<ColumnConfig>[
        ColumnConfig(
          id: _colDate,
          label: 'Date',
          orderIndex: 0,
          isLocked: true,
        ),
        ColumnConfig(
          id: _colMoveOrder,
          label: 'Move Order#',
          orderIndex: 1,
          isLocked: true,
        ),
        ColumnConfig(id: _colLocation, label: 'Location', orderIndex: 2),
        ColumnConfig(id: _colNotes, label: 'Notes', orderIndex: 3),
        ColumnConfig(id: _colStatus, label: 'Status', orderIndex: 4),
      ]);
    _updateVisibleColumns();
  }

  void _updateVisibleColumns() {
    _allColumns.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    _visibleColumns
      ..clear()
      ..addAll(_allColumns.where((c) => c.isVisible).map((c) => c.id));
  }

  Future<void> _loadColumnSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('move_orders_table_columns_config');
      if (jsonStr == null || jsonStr.trim().isEmpty) return;

      final List<dynamic> decoded = jsonDecode(jsonStr);
      final loadedMap = <String, ColumnConfig>{
        for (final raw in decoded)
          if (raw is Map)
            ColumnConfig.fromJson(Map<String, dynamic>.from(raw)).id:
                ColumnConfig.fromJson(Map<String, dynamic>.from(raw)),
      };

      if (!mounted) return;
      setState(() {
        for (final col in _allColumns) {
          final loaded = loadedMap[col.id];
          if (loaded == null) continue;
          col.isVisible = loaded.isVisible;
          col.orderIndex = loaded.orderIndex;
        }
        _updateVisibleColumns();
      });
    } catch (_) {}
  }

  Future<void> _saveColumnSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_allColumns.map((e) => e.toJson()).toList());
    await prefs.setString('move_orders_table_columns_config', jsonStr);
  }

  Future<void> _loadRows() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final warehouseNameById = <String, String>{};
      try {
        final warehouseResponse = await _apiClient.get('/warehouses');
        final warehousePayload = warehouseResponse.data;
        List<dynamic> warehouseList = const <dynamic>[];
        if (warehousePayload is Map<String, dynamic>) {
          final node = warehousePayload['data'];
          if (node is List) warehouseList = node;
        } else if (warehousePayload is List) {
          warehouseList = warehousePayload;
        }
        for (final raw in warehouseList.whereType<Map>()) {
          final map = Map<String, dynamic>.from(raw);
          final id = (map['id'] ?? '').toString().trim();
          final name = (map['name'] ?? map['warehouse_name'] ?? '')
              .toString()
              .trim();
          if (id.isNotEmpty && name.isNotEmpty) {
            warehouseNameById[id] = name;
          }
        }
      } catch (_) {}

      final queryParams = <String, dynamic>{};
      if (_statusFilter != 'all') {
        queryParams['status'] = _statusFilter;
      }
      final response = await _apiClient.get(
        '/move-orders',
        useCache: false,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final payload = response.data;
      List<dynamic> list = const <dynamic>[];
      if (payload is Map<String, dynamic>) {
        final dataNode = payload['data'];
        if (dataNode is List) list = dataNode;
      } else if (payload is List) {
        list = payload;
      }

      final rows = list
          .whereType<Map>()
          .map(
            (e) => _MoveOrderRow.fromJson(
              Map<String, dynamic>.from(e),
              warehouseNameById: warehouseNameById,
            ),
          )
          .where((row) => row.id.isNotEmpty)
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  List<_MoveOrderRow> get _filteredRows {
    return _rows;
  }

  void _openCustomizeColumnsDialog() {
    final tempVisibleColumns = Set<String>.from(_visibleColumns);
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        String search = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredColumns = _allColumns
                .where((column) {
                  if (search.trim().isEmpty) return true;
                  return column.label.toLowerCase().contains(
                    search.toLowerCase(),
                  );
                })
                .toList(growable: false);
            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: EdgeInsets.zero,
              backgroundColor: AppTheme.backgroundColor,
              surfaceTintColor: AppTheme.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.slidersHorizontal,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Customize Columns',
                            style: AppTheme.sectionHeader.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${tempVisibleColumns.length} of ${_allColumns.length} Selected',
                            style: AppTheme.metaHelper.copyWith(fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: const Icon(
                              LucideIcons.x,
                              size: 18,
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                      child: ZSearchField(
                        hintText: 'Search',
                        controller: searchController,
                        onChanged: (value) {
                          setDialogState(() => search = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredColumns.length,
                        itemBuilder: (context, index) {
                          final column = filteredColumns[index];
                          final isVisible = tempVisibleColumns.contains(
                            column.id,
                          );
                          return InkWell(
                            onTap: column.isLocked
                                ? null
                                : () {
                                    setDialogState(() {
                                      if (isVisible) {
                                        tempVisibleColumns.remove(column.id);
                                      } else {
                                        tempVisibleColumns.add(column.id);
                                      }
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.gripVertical,
                                    size: 14,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 10),
                                  Checkbox(
                                    value: isVisible,
                                    onChanged: column.isLocked
                                        ? null
                                        : (_) {
                                            setDialogState(() {
                                              if (isVisible) {
                                                tempVisibleColumns.remove(
                                                  column.id,
                                                );
                                              } else {
                                                tempVisibleColumns.add(
                                                  column.id,
                                                );
                                              }
                                            });
                                          },
                                  ),
                                  Expanded(
                                    child: Text(
                                      column.label,
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (column.isLocked)
                                    const Icon(
                                      LucideIcons.lock,
                                      size: 14,
                                      color: AppTheme.textMuted,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.borderColor),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                      child: Row(
                        children: [
                          ZButton.primary(
                            label: 'Save',
                            onPressed: () {
                              setState(() {
                                for (final col in _allColumns) {
                                  col.isVisible = tempVisibleColumns.contains(
                                    col.id,
                                  );
                                }
                                _updateVisibleColumns();
                              });
                              _saveColumnSettings();
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                          const SizedBox(width: 8),
                          ZButton.secondary(
                            label: 'Cancel',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(searchController.dispose);
  }

  void _openDetail(String id) {
    context.go('/$_orgId/inventory/move-orders/$id');
  }

  void _closeDetail() {
    context.go('/$_orgId/inventory/move-orders');
  }

  void _toggleAll(List<_MoveOrderRow> rows) {
    setState(() {
      final allSelected =
          rows.isNotEmpty && rows.every((r) => _selectedIds.contains(r.id));
      if (allSelected) {
        _selectedIds.removeAll(rows.map((e) => e.id));
      } else {
        _selectedIds.addAll(rows.map((e) => e.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      actions: [_buildTopActions()],
      child: _isDetailOpen ? _buildSplitView() : _buildMainList(),
    );
  }

  Widget _buildTopActions() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30,
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.go('/$_orgId/inventory/move-orders/create'),
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text(
                'New',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: AppTheme.backgroundColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ZTableMoreMenu(
            menuChildren: [
              MenuItemButton(
                onPressed: _loadRows,
                style: ZTableMoreMenu.menuItemButtonStyle(),
                child: const Text('Refresh List'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: _buildListControls(),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildSplitView() {
    return SplitListDetailLayout(
      leftWidth: 340,
      leftHeader: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Row(
          children: [
            Expanded(child: _buildStatusSelector()),
            const SizedBox(width: 8),
            _buildInlineListActions(),
          ],
        ),
      ),
      leftBody: _buildCompactList(),
      rightBody: _MoveOrderDetailPanel(id: widget.id!, onClose: _closeDetail),
    );
  }

  Widget _buildInlineListActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: ElevatedButton(
            onPressed: () =>
                context.go('/$_orgId/inventory/move-orders/create'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: AppTheme.successGreen,
              foregroundColor: AppTheme.backgroundColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Icon(LucideIcons.plus, size: 14),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 32,
          height: 32,
          child: OutlinedButton(
            onPressed: _loadRows,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              side: const BorderSide(color: AppTheme.borderColor),
              foregroundColor: AppTheme.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Icon(LucideIcons.moreHorizontal, size: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildListControls() {
    return Row(children: [_buildStatusSelector()]);
  }

  Widget _buildStatusSelector() {
    final currentLabel = _statusLabelMap[_statusFilter] ?? 'All Move Orders';
    return MenuAnchor(
      menuChildren: [
        ..._statusLabelMap.entries.map(
          (entry) => MenuItemButton(
            style: ZTableMoreMenu.menuItemButtonStyle(),
            onPressed: () {
              setState(() => _statusFilter = entry.key);
              _loadRows();
            },
            child: Text(entry.value),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentLabel,
                  style: AppTheme.pageTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 18,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: ZTableSkeleton(rows: 8, columns: 7),
      );
    }

    final rows = _filteredRows;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final tableWidth = _tableWidth < viewportWidth
            ? viewportWidth
            : _tableWidth;
        final scale = tableWidth / _tableWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                _buildHeaderRow(rows, scale),
                Expanded(
                  child: _error != null
                      ? _buildTableStateRow(
                          message: 'Failed to load Move Orders',
                          actionLabel: 'Retry',
                          onAction: _loadRows,
                        )
                      : rows.isEmpty
                      ? _buildTableStateRow(message: 'No move orders found.')
                      : ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, index) =>
                              _buildDataRow(rows[index], scale),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableStateRow({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderRow(List<_MoveOrderRow> rows, double scale) {
    final allSelected =
        rows.isNotEmpty && rows.every((r) => _selectedIds.contains(r.id));
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Center(
              child: ZTableHeaderMenu(
                wrapText: _shouldWrapText,
                onWrapChange: (v) => setState(() => _shouldWrapText = v),
                onCustomize: _openCustomizeColumnsDialog,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Center(
              child: Checkbox(
                value: allSelected,
                onChanged: (_) => _toggleAll(rows),
              ),
            ),
          ),
          for (final colId in _visibleColumns) _headerCell(colId, scale),
        ],
      ),
    );
  }

  Widget _buildDataRow(_MoveOrderRow row, double scale) {
    return Container(
      constraints: BoxConstraints(minHeight: _shouldWrapText ? 60 : 52),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 42),
          SizedBox(
            width: 36,
            child: Center(
              child: Checkbox(
                value: _selectedIds.contains(row.id),
                onChanged: (_) {
                  setState(() {
                    if (_selectedIds.contains(row.id)) {
                      _selectedIds.remove(row.id);
                    } else {
                      _selectedIds.add(row.id);
                    }
                  });
                },
              ),
            ),
          ),
          for (final colId in _visibleColumns) _rowCell(colId, row, scale),
        ],
      ),
    );
  }

  Widget _buildCompactList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: ZTableSkeleton(rows: 8, columns: 1),
      );
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final rows = _filteredRows;
    if (rows.isEmpty) {
      return const Center(child: Text('No move orders found.'));
    }

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final selected = row.id == widget.id;
        final hovered = _hoveredCompactRowId == row.id;
        final rowDecoration = selected
            ? const BoxDecoration(color: AppTheme.bgHover)
            : hovered
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    AppTheme.infoBg.withValues(alpha: 0.95),
                    AppTheme.selectionActiveBg.withValues(alpha: 0.85),
                  ],
                ),
              )
            : const BoxDecoration(color: AppTheme.backgroundColor);

        return MouseRegion(
          onEnter: (_) {
            if (_hoveredCompactRowId == row.id) return;
            setState(() => _hoveredCompactRowId = row.id);
          },
          onExit: (_) {
            if (_hoveredCompactRowId != row.id) return;
            setState(() => _hoveredCompactRowId = null);
          },
          child: InkWell(
            onTap: () => _openDetail(row.id),
            child: Container(
              decoration: rowDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.moveOrderNumber,
                          style: AppTheme.bodyText.copyWith(
                            color: AppTheme.primaryBlueDark,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          row.warehouseLabel,
                          style: AppTheme.metaHelper.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_formatDate(row.moveDate), style: AppTheme.metaHelper),
                  const SizedBox(height: 2),
                  Text(
                    row.status.toUpperCase(),
                    style: AppTheme.metaHelper.copyWith(
                      color: _statusColor(row.status),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _headerCell(String colId, double scale) {
    String label;
    switch (colId) {
      case _colDate:
        label = 'DATE';
        break;
      case _colMoveOrder:
        label = 'MOVE ORDER#';
        break;
      case _colLocation:
        label = 'LOCATION';
        break;
      case _colNotes:
        label = 'NOTES';
        break;
      case _colStatus:
        label = 'STATUS';
        break;
      default:
        label = colId;
    }

    return SizedBox(
      width: _columnWidth(colId, scale),
      child: Text(label, style: AppTheme.tableHeader),
    );
  }

  Widget _rowCell(String colId, _MoveOrderRow row, double scale) {
    String text;
    TextStyle style = AppTheme.bodyText;
    switch (colId) {
      case _colDate:
        text = _formatDate(row.moveDate);
        break;
      case _colMoveOrder:
        text = row.moveOrderNumber;
        style = AppTheme.bodyText.copyWith(color: AppTheme.primaryBlueDark);
        break;
      case _colLocation:
        text = row.warehouseLabel;
        break;
      case _colNotes:
        text = row.notes;
        break;
      case _colStatus:
        text = row.status.toUpperCase();
        style = AppTheme.bodyText.copyWith(color: _statusColor(row.status));
        break;
      default:
        text = '';
    }

    final cellChild = Text(
      text,
      style: style,
      maxLines: _shouldWrapText ? null : 1,
      overflow: _shouldWrapText ? TextOverflow.visible : TextOverflow.ellipsis,
    );

    return SizedBox(
      width: _columnWidth(colId, scale),
      child: InkWell(
        onTap: colId == _colMoveOrder ? () => _openDetail(row.id) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: cellChild,
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd-MM-yyyy').format(date);
  }

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
        return AppTheme.successDark;
      case 'draft':
        return AppTheme.primaryBlueDark;
      default:
        return AppTheme.textPrimary;
    }
  }
}

class _MoveOrderDetailPanel extends StatefulWidget {
  const _MoveOrderDetailPanel({required this.id, required this.onClose});

  final String id;
  final VoidCallback onClose;

  @override
  State<_MoveOrderDetailPanel> createState() => _MoveOrderDetailPanelState();
}

class _MoveOrderDetailPanelState extends State<_MoveOrderDetailPanel> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  bool _showPdfView = false;
  String? _error;
  Map<String, dynamic>? _detail;
  Map<String, String> _warehouseNameById = const <String, String>{};
  Map<String, String> _userNameById = const <String, String>{};
  Map<String, String> _productNameById = const <String, String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _MoveOrderDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiClient.get('/move-orders/${widget.id}');
      final payload = response.data;
      if (payload is Map<String, dynamic>) {
        await _loadLookups(payload);
        if (!mounted) return;
        setState(() {
          _detail = payload;
          _isLoading = false;
        });
      } else {
        setState(() {
          _detail = null;
          _isLoading = false;
          _error = 'Invalid move order response';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLookups(Map<String, dynamic> detail) async {
    final warehouseNameById = <String, String>{};
    final userNameById = <String, String>{};
    final productNameById = <String, String>{};

    Future<void> loadWarehouses() async {
      try {
        final response = await _apiClient.get('/warehouses');
        final payload = response.data;
        List<dynamic> list = const <dynamic>[];
        if (payload is Map<String, dynamic>) {
          final node = payload['data'];
          if (node is List) list = node;
        } else if (payload is List) {
          list = payload;
        }
        for (final raw in list.whereType<Map>()) {
          final map = Map<String, dynamic>.from(raw);
          final id = (map['id'] ?? '').toString().trim();
          final name = (map['name'] ?? map['warehouse_name'] ?? '')
              .toString()
              .trim();
          if (id.isNotEmpty && name.isNotEmpty) {
            warehouseNameById[id] = name;
          }
        }
      } catch (_) {}
    }

    Future<void> loadUsers() async {
      try {
        final response = await _apiClient.get('/users');
        final payload = response.data;
        List<dynamic> list = const <dynamic>[];
        if (payload is Map<String, dynamic>) {
          final node = payload['data'];
          if (node is List) list = node;
        } else if (payload is List) {
          list = payload;
        }
        for (final raw in list.whereType<Map>()) {
          final map = Map<String, dynamic>.from(raw);
          final id = (map['id'] ?? '').toString().trim();
          final name =
              (map['full_name'] ??
                      map['fullName'] ??
                      map['display_name'] ??
                      map['name'] ??
                      '')
                  .toString()
                  .trim();
          if (id.isNotEmpty && name.isNotEmpty) {
            userNameById[id] = name;
          }
        }
      } catch (_) {}
    }

    Future<void> loadProducts() async {
      try {
        final response = await _apiClient.get(
          '/products',
          queryParameters: const {'limit': 500},
        );
        final payload = response.data;
        List<dynamic> list = const <dynamic>[];
        if (payload is Map<String, dynamic>) {
          final node = payload['data'];
          if (node is List) list = node;
        } else if (payload is List) {
          list = payload;
        }
        for (final raw in list.whereType<Map>()) {
          final map = Map<String, dynamic>.from(raw);
          final id = (map['id'] ?? '').toString().trim();
          final name =
              (map['product_name'] ?? map['name'] ?? map['item_name'] ?? '')
                  .toString()
                  .trim();
          if (id.isNotEmpty && name.isNotEmpty) {
            productNameById[id] = name;
          }
        }
      } catch (_) {}
    }

    Future<void> loadMissingProductsFromDetail() async {
      final items =
          (detail['items'] as List?)?.whereType<Map>().toList() ??
          const <Map>[];
      final missingIds = items
          .map((item) => (item['product_id'] ?? '').toString().trim())
          .where((id) => id.isNotEmpty && !productNameById.containsKey(id))
          .toSet()
          .toList(growable: false);
      if (missingIds.isEmpty) return;

      for (final productId in missingIds) {
        try {
          final response = await _apiClient.get('/products/$productId');
          dynamic payload = response.data;
          if (payload is Map<String, dynamic> && payload['data'] is Map) {
            payload = payload['data'];
          }
          if (payload is! Map) continue;
          final map = Map<String, dynamic>.from(payload);
          final id = (map['id'] ?? productId).toString().trim();
          final name =
              (map['product_name'] ?? map['name'] ?? map['item_name'] ?? '')
                  .toString()
                  .trim();
          if (id.isNotEmpty && name.isNotEmpty) {
            productNameById[id] = name;
          }
        } catch (_) {}
      }
    }

    await Future.wait(<Future<void>>[
      loadWarehouses(),
      loadUsers(),
      loadProducts(),
    ]);
    await loadMissingProductsFromDetail();

    if (!mounted) return;
    setState(() {
      _warehouseNameById = warehouseNameById;
      _userNameById = userNameById;
      _productNameById = productNameById;
    });
  }

  String _resolveItemDisplayName(Map item) {
    final productId = (item['product_id'] ?? '').toString().trim();
    final fromLookup = _productNameById[productId]?.trim() ?? '';
    if (fromLookup.isNotEmpty) {
      return fromLookup;
    }
    return _resolveMoveOrderItemDisplayName(item);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _MoveOrderDetailSkeleton();
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    final detail = _detail;
    if (detail == null) {
      return const Center(child: Text('Move order not found.'));
    }

    final items =
        (detail['items'] as List?)?.whereType<Map>().toList() ?? const <Map>[];

    final status = (detail['status'] ?? 'DRAFT').toString().toUpperCase();
    final statusColor = status == 'COMPLETED'
        ? AppTheme.successDark
        : AppTheme.primaryBlueDark;

    return DocumentViewModeSwitcher(
      showPdfView: _showPdfView,
      onChanged: (val) => setState(() => _showPdfView = val),
      normalView: _buildNormalDetail(detail, items),
      pdfView: Stack(
        children: [
          ZerpaiDocumentView(
            documentType: 'MOVE ORDER',
            documentNumber: (detail['move_order_number'] ?? 'MO-').toString(),
            status: status,
            statusColor: statusColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _overviewCardPdf(detail),
                const SizedBox(height: 14),
                Expanded(child: _itemsTablePdf(items)),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              onPressed: widget.onClose,
              icon: const Icon(LucideIcons.x, color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalDetail(Map<String, dynamic> detail, List<Map> items) {
    final moveOrderNumber = _displayText(
      detail['move_order_number'],
      fallback: 'Move Order',
    );
    final moveDate = _displayText(detail['move_date']);
    final completedAt = _displayText(detail['completed_at']);
    final locationName = _lookupDisplayName(
      detail['warehouse_id'],
      _warehouseNameById,
    );
    final assigneeName = _lookupDisplayName(
      detail['assignee_id'],
      _userNameById,
    );
    final status = _displayText(
      detail['status'],
      fallback: 'draft',
    ).toUpperCase();
    final statusColor = status.toLowerCase() == 'completed'
        ? AppTheme.successDark
        : AppTheme.primaryBlueDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MOVE ORDER',
                      style: AppTheme.sectionHeader.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Move Order# $moveOrderNumber',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: AppTheme.metaHelper.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(LucideIcons.x, color: AppTheme.errorRed),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              if (status != 'COMPLETED')
                _buildSecondaryActionButton(
                  'Mark as Completed',
                  LucideIcons.checkCircle2,
                  () => _handleMarkAsCompleted(detail),
                ),
              if (status != 'COMPLETED') const SizedBox(width: 10),
              _buildMoveOrderPdfPrintMenu(),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: OverviewSectionCard(
                        entries: [
                          OverviewEntry(
                            label: 'Date',
                            value: _formatDateValue(moveDate),
                          ),
                          OverviewEntry(
                            label: 'Moved Date',
                            value: _formatDateValue(completedAt),
                          ),
                          OverviewEntry(
                            label: 'Location Name',
                            value: locationName,
                          ),
                          OverviewEntry(label: 'Status', value: status),
                          OverviewEntry(label: 'Assignee', value: assigneeName),
                          OverviewEntry(
                            label: 'Notes',
                            value: _displayText(detail['notes']),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    _summaryTotalCard(
                      'Total Quantity',
                      _normalTotalQtyLabel(items),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _itemsTableNormal(items),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 30,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.bgLight,
          foregroundColor: AppTheme.textPrimary,
          side: const BorderSide(color: AppTheme.borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  Widget _buildMoveOrderPdfPrintMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'pdf') {
          setState(() => _showPdfView = true);
          return;
        }
        ZerpaiToast.info(
          context,
          'Switch to PDF View, then use browser Print.',
        );
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'pdf',
          child: Row(
            children: [
              Icon(LucideIcons.fileText, size: 14),
              SizedBox(width: 8),
              Text('Show PDF View'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'print',
          child: Row(
            children: [
              Icon(LucideIcons.printer, size: 14),
              SizedBox(width: 8),
              Text('Print'),
            ],
          ),
        ),
      ],
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.fileText, size: 14, color: AppTheme.textPrimary),
            SizedBox(width: 6),
            Text(
              'PDF/Print',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              LucideIcons.chevronDown,
              size: 12,
              color: AppTheme.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMarkAsCompleted(Map<String, dynamic> detail) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Mark as Completed',
      message: 'Are you sure you want to mark this move order as completed?',
      confirmLabel: 'Complete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.success,
    );
    if (!confirmed) return;

    try {
      final completedBy = (detail['assignee_id'] ?? '').toString().trim();
      await _apiClient.post(
        '/move-orders/${widget.id}/complete',
        data: completedBy.isNotEmpty
            ? <String, dynamic>{'completed_by': completedBy}
            : <String, dynamic>{},
      );
      if (!mounted) return;
      ZerpaiToast.success(context, 'Move order marked as completed');
      await _load();
    } catch (_) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to mark move order as completed');
    }
  }

  String _normalTotalQtyLabel(List<Map> items) {
    double total = 0;
    for (final item in items) {
      final qty = double.tryParse((item['qty'] ?? '').toString().trim()) ?? 0;
      total += qty;
    }
    return total.toStringAsFixed(2);
  }

  Widget _summaryTotalCard(String label, String value) {
    return Container(
      width: 220,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 38,
              height: 1,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewCardPdf(Map<String, dynamic> detail) {
    final moveDate = _displayText(detail['move_date']);
    final completedAt = _displayText(detail['completed_at']);
    final locationName = _lookupDisplayName(
      detail['warehouse_id'],
      _warehouseNameById,
    );
    final assigneeName = _lookupDisplayName(
      detail['assignee_id'],
      _userNameById,
    );
    final notes = _displayText(detail['notes']);

    return ZerpaiDocumentMetaRow(
      children: [
        ZerpaiDocumentInfoBlock(
          label: 'DATE',
          value: _formatDateValue(moveDate),
        ),
        ZerpaiDocumentInfoBlock(
          label: 'MOVED DATE',
          value: _formatDateValue(completedAt),
        ),
        ZerpaiDocumentInfoBlock(label: 'LOCATION NAME', value: locationName),
        ZerpaiDocumentInfoBlock(label: 'ASSIGNEE', value: assigneeName),
        ZerpaiDocumentInfoBlock(label: 'NOTES', value: notes),
      ],
    );
  }

  Widget _itemsTablePdf(List<Map> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZerpaiDocumentTableHeader(
          children: [
            ZerpaiDocumentHeaderCell('#', width: 40),
            ZerpaiDocumentHeaderCell('ITEMS & DESCRIPTION', flex: 1),
            ZerpaiDocumentHeaderCell('QUANTITY TRANSFERRED', width: 180),
          ],
        ),
        if (items.isEmpty)
          const ZerpaiDocumentTableRow(
            children: [ZerpaiDocumentDataCell('No items found.', flex: 1)],
          ),
        for (final item in items)
          ZerpaiDocumentTableRow(
            children: [
              ZerpaiDocumentDataCell(
                (items.indexOf(item) + 1).toString(),
                width: 40,
              ),
              ZerpaiDocumentDataCell(_resolveItemDisplayName(item), flex: 1),
              ZerpaiDocumentDataCell(
                _formatQuantity(item['qty']),
                width: 180,
                align: TextAlign.end,
              ),
            ],
          ),
      ],
    );
  }

  Widget _itemsTableNormal(List<Map> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: AppTheme.tableHeaderBg,
            alignment: Alignment.centerLeft,
            child: Text('Items', style: AppTheme.tableHeader),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppTheme.backgroundColor,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text('#', style: AppTheme.tableHeader),
                ),
                SizedBox(
                  width: 260,
                  child: Text(
                    'ITEMS & DESCRIPTION',
                    style: AppTheme.tableHeader,
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: Text(
                    'QUANTITY TRANSFERRED',
                    style: AppTheme.tableHeader,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          for (final item in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      (items.indexOf(item) + 1).toString(),
                      style: AppTheme.bodyText,
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: Text(
                      _resolveItemDisplayName(item),
                      style: AppTheme.bodyText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: Text(
                      _formatQuantity(item['qty']),
                      style: AppTheme.bodyText,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('No items found.', style: AppTheme.bodyText),
            ),
        ],
      ),
    );
  }
}

class _MoveOrderDetailSkeleton extends StatelessWidget {
  const _MoveOrderDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ZBone(width: 220, height: 28),
          const SizedBox(height: 8),
          const ZBone(width: 200, height: 20),
          const SizedBox(height: 10),
          const ZBone(width: 70, height: 24, borderRadius: 4),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(14),
            child: const Column(
              children: [
                _SkeletonOverviewRow(),
                SizedBox(height: 14),
                _SkeletonOverviewRow(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: AppTheme.tableHeaderBg,
                  alignment: Alignment.centerLeft,
                  child: const ZBone(width: 70, height: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 40, child: ZBone(height: 12)),
                      SizedBox(width: 260, child: ZBone(height: 12)),
                      SizedBox(width: 180, child: ZBone(height: 12)),
                    ],
                  ),
                ),
                for (int i = 0; i < 3; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 40, child: ZBone(height: 12)),
                        SizedBox(width: 260, child: ZBone(height: 12)),
                        SizedBox(width: 180, child: ZBone(height: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonOverviewRow extends StatelessWidget {
  const _SkeletonOverviewRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: ZBone(height: 12)),
        SizedBox(width: 12),
        Expanded(child: ZBone(height: 12)),
        SizedBox(width: 12),
        Expanded(child: ZBone(height: 12)),
      ],
    );
  }
}
