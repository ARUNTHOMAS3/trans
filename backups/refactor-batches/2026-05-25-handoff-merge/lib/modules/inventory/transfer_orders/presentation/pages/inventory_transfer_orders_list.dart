import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web/web.dart' as import_web;
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_transfer_model.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/repositories/transfers_repository.dart';
import 'package:zerpai_erp/modules/inventory/repositories/warehouse_repository.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/document/document_view_mode_switcher.dart';
import 'package:zerpai_erp/shared/widgets/document/zerpai_document_view.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_search_field.dart';
import 'package:zerpai_erp/shared/widgets/tables/overview_section_card.dart';
import 'package:zerpai_erp/shared/widgets/tables/split_list_detail_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class InventoryTransferOrdersListScreen extends StatefulWidget {
  const InventoryTransferOrdersListScreen({super.key, this.id});

  final String? id;

  @override
  State<InventoryTransferOrdersListScreen> createState() =>
      _InventoryTransferOrdersListScreenState();
}

enum _TransferSortField { date, createdTime, lastModifiedTime }

_TransferSortField _sortFieldFromString(String value) {
  switch (value) {
    case 'created_time':
      return _TransferSortField.createdTime;
    case 'last_modified_time':
      return _TransferSortField.lastModifiedTime;
    case 'date':
    default:
      return _TransferSortField.date;
  }
}

String _sortFieldToString(_TransferSortField field) {
  switch (field) {
    case _TransferSortField.createdTime:
      return 'created_time';
    case _TransferSortField.lastModifiedTime:
      return 'last_modified_time';
    case _TransferSortField.date:
      return 'date';
  }
}

class _TransferListColumn {
  const _TransferListColumn({
    required this.id,
    required this.label,
    required this.width,
    this.locked = false,
  });

  final String id;
  final String label;
  final double width;
  final bool locked;
}

class _TransferCustomView {
  const _TransferCustomView({
    required this.id,
    required this.name,
    required this.statusFilter,
    required this.visibleColumnIds,
    required this.clipText,
    required this.sortField,
    required this.sortAscending,
  });

  final String id;
  final String name;
  final String statusFilter;
  final List<String> visibleColumnIds;
  final bool clipText;
  final _TransferSortField sortField;
  final bool sortAscending;

  factory _TransferCustomView.fromJson(Map<String, dynamic> json) {
    return _TransferCustomView(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      statusFilter: (json['status_filter'] ?? 'all').toString(),
      visibleColumnIds:
          (json['visible_column_ids'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .toList(growable: false),
      clipText: json['clip_text'] == true,
      sortField: _sortFieldFromString(
        (json['sort_field'] ?? 'date').toString(),
      ),
      sortAscending: json['sort_ascending'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'status_filter': statusFilter,
      'visible_column_ids': visibleColumnIds,
      'clip_text': clipText,
      'sort_field': _sortFieldToString(sortField),
      'sort_ascending': sortAscending,
    };
  }
}

class _InventoryTransferOrdersListScreenState
    extends State<InventoryTransferOrdersListScreen> {
  static const String _colDate = 'date';
  static const String _colTransferOrder = 'transfer_order';
  static const String _colReason = 'reason';
  static const String _colStatus = 'status';
  static const String _colQuantity = 'quantity';
  static const String _colSourceLocation = 'source_location';
  static const String _colDestinationLocation = 'destination_location';
  static const String _colCreatedBy = 'created_by';
  static const String _colCreatedTime = 'created_time';
  static const String _colLastModifiedBy = 'last_modified_by';
  static const String _colLastModifiedTime = 'last_modified_time';
  static const String _colQuantityTransferred = 'quantity_transferred';

  static const List<_TransferListColumn> _allColumns = <_TransferListColumn>[
    _TransferListColumn(id: _colDate, label: 'Date', width: 136, locked: true),
    _TransferListColumn(
      id: _colTransferOrder,
      label: 'Transfer Order#',
      width: 150,
      locked: true,
    ),
    _TransferListColumn(id: _colReason, label: 'Reason', width: 136),
    _TransferListColumn(id: _colStatus, label: 'Status', width: 136),
    _TransferListColumn(id: _colQuantity, label: 'Quantity', width: 124),
    _TransferListColumn(
      id: _colSourceLocation,
      label: 'Source Location',
      width: 170,
    ),
    _TransferListColumn(
      id: _colDestinationLocation,
      label: 'Destination Location',
      width: 170,
    ),
    _TransferListColumn(id: _colCreatedBy, label: 'Created By', width: 136),
    _TransferListColumn(id: _colCreatedTime, label: 'Created Time', width: 136),
    _TransferListColumn(
      id: _colLastModifiedBy,
      label: 'Last Modified By',
      width: 136,
    ),
    _TransferListColumn(
      id: _colLastModifiedTime,
      label: 'Last Modified Time',
      width: 152,
    ),
    _TransferListColumn(
      id: _colQuantityTransferred,
      label: 'Quantity Transferred',
      width: 152,
    ),
  ];

  final TransfersRepository _repository = TransfersRepository();
  final Set<String> _selectedIds = <String>{};
  final Uuid _uuid = const Uuid();

  bool _isLoading = true;
  bool _clipText = true;
  String? _error;
  List<StockTransfer> _rows = const <StockTransfer>[];
  String _statusFilter = 'all';
  String? _activeCustomViewId;
  _TransferSortField _sortField = _TransferSortField.date;
  bool _sortAscending = false;
  List<_TransferCustomView> _customViews = const <_TransferCustomView>[];
  final Set<String> _visibleColumnIds = <String>{
    _colDate,
    _colTransferOrder,
    _colReason,
    _colStatus,
    _colQuantity,
    _colSourceLocation,
    _colDestinationLocation,
    _colCreatedBy,
    _colCreatedTime,
    _colLastModifiedBy,
    _colLastModifiedTime,
  };

  static const Map<String, String> _statusLabelMap = <String, String>{
    'all': 'All Transfer Orders',
    'transferred': 'Transferred',
    'in_transit': 'In Transit',
    'draft': 'Draft',
    'partial_transferred': 'Partially Transferred',
    'pending': 'Pending',
    'cancelled': 'Void',
  };

  String get _orgId => GoRouterState.of(context).pathParameters['orgSystemId']!;
  bool get _isDetailOpen => widget.id != null && widget.id!.trim().isNotEmpty;

  String get _prefsScope {
    try {
      final box = Hive.box('config');
      final raw = (box.get('user_data') ?? '').toString().trim();
      if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final userId = (decoded['id'] ?? '').toString().trim();
          if (userId.isNotEmpty) {
            return '$_orgId::$userId';
          }
        }
      }
    } catch (_) {}
    return _orgId;
  }

  String get _systemViewId => 'system:$_statusFilter';

  String get _activeViewId => _activeCustomViewId == null
      ? _systemViewId
      : 'custom:$_activeCustomViewId';

  String get _customViewsKey => 'transfer_orders_custom_views::$_prefsScope';

  String get _lastViewKey => 'transfer_orders_last_view::$_prefsScope';

  String _viewPrefsKey(String viewId) =>
      'transfer_orders_view_prefs::$_prefsScope::$viewId';

  List<_TransferListColumn> get _visibleColumns => _allColumns
      .where((column) => _visibleColumnIds.contains(column.id))
      .toList(growable: false);

  double get _tableWidth =>
      42 +
      36 +
      _visibleColumns.fold<double>(0, (sum, column) => sum + column.width);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateFromRoute();
      _bootstrapScreen();
    });
  }

  Future<void> _bootstrapScreen() async {
    AppLogger.debug(
      '🚀 _bootstrapScreen started',
      module: 'inventory_transfer_orders',
    );
    // Start data fetch immediately; do not block on preference hydration.
    _loadRows();
    try {
      // Parallelize preferences load for speed
      await Future.wait([_loadSavedViews(), _restoreActiveViewPreferences()]);
      AppLogger.debug(
        '✅ Preferences hydrated',
        module: 'inventory_transfer_orders',
      );
    } catch (e) {
      AppLogger.error(
        '❌ Preferences hydration failed',
        error: e,
        module: 'inventory_transfer_orders',
      );
    }

    AppLogger.debug(
      '🏁 _bootstrapScreen finished',
      module: 'inventory_transfer_orders',
    );
  }

  Future<void> _loadRows({bool forceRefresh = false}) async {
    AppLogger.debug(
      '🔄 _loadRows started (forceRefresh: $forceRefresh)',
      module: 'inventory_transfer_orders',
    );
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stopwatch = Stopwatch()..start();
      final rows = await _repository.getTransfers(forceRefresh: forceRefresh);
      stopwatch.stop();

      AppLogger.performance(
        'getTransfers API call',
        stopwatch.elapsed,
        metrics: {'count': rows.length},
      );

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _isLoading = false;
      });
      AppLogger.debug(
        '✅ _loadRows finished',
        module: 'inventory_transfer_orders',
      );
    } catch (e, st) {
      AppLogger.error(
        '❌ _loadRows failed',
        error: e,
        stackTrace: st,
        module: 'inventory_transfer_orders',
      );
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _hydrateFromRoute() {
    final status = GoRouterState.of(context).uri.queryParameters['status'];
    if (status != null && _statusLabelMap.containsKey(status)) {
      _statusFilter = status;
      _activeCustomViewId = null;
    }
  }

  void _syncRoute() {
    final Map<String, String> query = <String, String>{};
    if (_statusFilter != 'all') {
      query['status'] = _statusFilter;
    }
    final queryString = query.isEmpty
        ? ''
        : '?${query.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    context.go('/$_orgId/inventory/transfer-orders$queryString');
  }

  Future<void> _loadSavedViews() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customViewsKey);
    if (raw == null || raw.trim().isEmpty) {
      if (!mounted) return;
      setState(() => _customViews = const <_TransferCustomView>[]);
      return;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final views = decoded
          .map(
            (item) => _TransferCustomView.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .where(
            (view) => view.id.trim().isNotEmpty && view.name.trim().isNotEmpty,
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() => _customViews = views);
    } catch (_) {
      if (!mounted) return;
      setState(() => _customViews = const <_TransferCustomView>[]);
    }
  }

  Future<void> _persistCustomViews() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customViewsKey,
      jsonEncode(
        _customViews.map((view) => view.toJson()).toList(growable: false),
      ),
    );
  }

  Future<void> _restoreActiveViewPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final lastViewId = prefs.getString(_lastViewKey);
    if (lastViewId == null || lastViewId.trim().isEmpty) {
      await _restoreViewPreferences(_activeViewId);
      return;
    }

    if (lastViewId.startsWith('custom:')) {
      final customId = lastViewId.substring('custom:'.length);
      _TransferCustomView? match;
      for (final view in _customViews) {
        if (view.id == customId) {
          match = view;
          break;
        }
      }
      if (match != null) {
        _applyCustomView(match, syncRoute: false);
      }
    } else if (lastViewId.startsWith('system:')) {
      final systemStatus = lastViewId.substring('system:'.length);
      if (_statusLabelMap.containsKey(systemStatus)) {
        _statusFilter = systemStatus;
        _activeCustomViewId = null;
      }
    }

    await _restoreViewPreferences(_activeViewId);
  }

  Future<void> _restoreViewPreferences(String viewId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_viewPrefsKey(viewId));
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final visibleColumns =
          (decoded['visible_column_ids'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .where((value) => _allColumns.any((column) => column.id == value))
              .toSet();
      if (visibleColumns.isNotEmpty) {
        _visibleColumnIds
          ..clear()
          ..addAll(visibleColumns);
      }
      _clipText = decoded['clip_text'] == true;
      _sortField = _sortFieldFromString(
        (decoded['sort_field'] ?? 'date').toString(),
      );
      _sortAscending = decoded['sort_ascending'] == true;
    } catch (_) {}
  }

  Future<void> _persistCurrentViewPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _viewPrefsKey(_activeViewId),
      jsonEncode(<String, dynamic>{
        'visible_column_ids': _visibleColumnIds.toList(growable: false),
        'clip_text': _clipText,
        'sort_field': _sortFieldToString(_sortField),
        'sort_ascending': _sortAscending,
      }),
    );
    await prefs.setString(_lastViewKey, _activeViewId);
  }

  Future<void> _saveCurrentAsCustomView(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      if (!mounted) return;
      ZerpaiToast.info(context, 'Enter a custom view name');
      return;
    }

    final normalized = trimmed.toLowerCase();
    final existingIndex = _customViews.indexWhere(
      (view) => view.name.trim().toLowerCase() == normalized,
    );

    final customView = _TransferCustomView(
      id: existingIndex >= 0 ? _customViews[existingIndex].id : _uuid.v4(),
      name: trimmed,
      statusFilter: _statusFilter,
      visibleColumnIds: _visibleColumnIds.toList(growable: false),
      clipText: _clipText,
      sortField: _sortField,
      sortAscending: _sortAscending,
    );

    final updated = List<_TransferCustomView>.from(_customViews);
    if (existingIndex >= 0) {
      updated[existingIndex] = customView;
    } else {
      updated.add(customView);
    }
    updated.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    setState(() {
      _customViews = updated;
      _activeCustomViewId = customView.id;
    });
    await _persistCustomViews();
    await _persistCurrentViewPreferences();
    _syncRoute();
    if (mounted) {
      ZerpaiToast.success(context, 'Custom view saved');
    }
  }

  Future<void> _deleteCustomView(_TransferCustomView view) async {
    setState(() {
      _customViews = _customViews
          .where((item) => item.id != view.id)
          .toList(growable: false);
      if (_activeCustomViewId == view.id) {
        _activeCustomViewId = null;
        _statusFilter = 'all';
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_viewPrefsKey('custom:${view.id}'));
    await _persistCustomViews();
    await _persistCurrentViewPreferences();
    _syncRoute();
  }

  void _applyCustomView(_TransferCustomView view, {bool syncRoute = true}) {
    _activeCustomViewId = view.id;
    _statusFilter = view.statusFilter;
    _visibleColumnIds
      ..clear()
      ..addAll(
        view.visibleColumnIds.where(
          (id) => _allColumns.any((column) => column.id == id),
        ),
      );
    _clipText = view.clipText;
    _sortField = view.sortField;
    _sortAscending = view.sortAscending;
    if (syncRoute) {
      _syncRoute();
    }
  }

  List<StockTransfer> get _filteredRows {
    final filtered = _statusFilter == 'all'
        ? List<StockTransfer>.from(_rows)
        : _rows
              .where((row) {
                final status = row.status.trim().toLowerCase();
                switch (_statusFilter) {
                  case 'transferred':
                    return status == 'received' || status == 'transferred';
                  case 'partial_transferred':
                    return status == 'partial_transferred';
                  case 'cancelled':
                    return status == 'cancelled';
                  default:
                    return status == _statusFilter;
                }
              })
              .toList(growable: false);

    filtered.sort((a, b) {
      final int comparison;
      switch (_sortField) {
        case _TransferSortField.createdTime:
          comparison = a.createdAt.compareTo(b.createdAt);
        case _TransferSortField.lastModifiedTime:
          comparison = a.updatedAt.compareTo(b.updatedAt);
        case _TransferSortField.date:
          comparison = a.transferDate.compareTo(b.transferDate);
      }
      return _sortAscending ? comparison : -comparison;
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final activeCustomView = _customViews
        .cast<_TransferCustomView?>()
        .firstWhere(
          (view) => view?.id == _activeCustomViewId,
          orElse: () => null,
        );
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      actions: _isDetailOpen ? const [] : [_buildTopActions()],
      child: _isDetailOpen
          ? _buildSplitView(activeCustomView)
          : _buildMainList(activeCustomView),
    );
  }

  Widget _buildMainList(_TransferCustomView? activeCustomView) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [_buildViewSelector(activeCustomView), const Spacer()],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildSplitView(_TransferCustomView? activeCustomView) {
    return SplitListDetailLayout(
      leftHeader: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Row(
          children: [
            Expanded(child: _buildViewSelector(activeCustomView)),
            const SizedBox(width: 8),
            _buildTopActions(),
          ],
        ),
      ),
      leftBody: _buildCompactList(),
      rightBody: _TransferOrderDetailPanel(
        id: widget.id!,
        repository: _repository,
        onClose: () => context.go('/$_orgId/inventory/transfer-orders'),
        onRefreshList: () => _loadRows(forceRefresh: true),
      ),
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
                  context.go('/$_orgId/inventory/transfer-orders/create'),
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text(
                'New',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
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
          _buildMoreActionsMenu(),
        ],
      ),
    );
  }

  Widget _buildViewSelector(_TransferCustomView? activeCustomView) {
    final currentLabel =
        activeCustomView?.name ??
        _statusLabelMap[_statusFilter] ??
        'All Transfer Orders';
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppTheme.backgroundColor),
        surfaceTintColor: WidgetStatePropertyAll(AppTheme.backgroundColor),
        side: WidgetStatePropertyAll(BorderSide(color: AppTheme.borderColor)),
      ),
      menuChildren: [
        ..._statusLabelMap.entries.map(
          (entry) => MenuItemButton(
            style: _menuItemStyle(),
            onPressed: () {
              setState(() {
                _statusFilter = entry.key;
                _activeCustomViewId = null;
              });
              _syncRoute();
              _persistCurrentViewPreferences();
            },
            trailingIcon: const Icon(
              LucideIcons.star,
              size: 14,
              color: AppTheme.borderColor,
            ),
            child: Text(entry.value.replaceFirst(' Transfer Orders', '')),
          ),
        ),
        if (_customViews.isNotEmpty) ...[
          const Divider(height: 1, color: AppTheme.borderColor),
          ..._customViews.map(
            (view) => MenuItemButton(
              style: _menuItemStyle(),
              onPressed: () async {
                setState(() => _applyCustomView(view, syncRoute: false));
                await _persistCurrentViewPreferences();
                _syncRoute();
              },
              trailingIcon: _activeCustomViewId == view.id
                  ? const Icon(
                      LucideIcons.check,
                      size: 14,
                      color: AppTheme.primaryBlue,
                    )
                  : const Icon(
                      LucideIcons.star,
                      size: 14,
                      color: AppTheme.borderColor,
                    ),
              child: Text(view.name),
            ),
          ),
        ],
        const Divider(height: 1, color: AppTheme.borderColor),
        MenuItemButton(
          style: _menuItemStyle(),
          onPressed: _promptNewCustomView,
          leadingIcon: const Icon(
            LucideIcons.plusCircle,
            size: 14,
            color: AppTheme.primaryBlue,
          ),
          child: const Text('New Custom View'),
        ),
        if (activeCustomView != null)
          MenuItemButton(
            style: _menuItemStyle(),
            onPressed: () => _deleteCustomView(activeCustomView),
            leadingIcon: const Icon(
              LucideIcons.trash2,
              size: 14,
              color: AppTheme.errorRed,
            ),
            child: const Text('Delete Current Custom View'),
          ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentLabel,
                  style: AppTheme.pageTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(width: 6),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 14,
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
        child: ZTableSkeleton(rows: 8, columns: 10),
      );
    }
    final rows = _filteredRows;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final tableWidth = _tableWidth < viewportWidth
            ? viewportWidth
            : _tableWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                _buildHeaderRow(rows),
                Expanded(
                  child: _error != null
                      ? _buildTableStateRow(
                          message: 'Unable to load transfer orders.',
                          actionLabel: 'Retry',
                          onAction: () => _loadRows(forceRefresh: true),
                        )
                      : rows.isEmpty
                      ? _buildTableStateRow(
                          message: 'No transfer orders found.',
                        )
                      : ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, index) =>
                              _buildDataRow(rows[index]),
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

  Widget _buildHeaderRow(List<StockTransfer> rows) {
    final allSelected =
        rows.isNotEmpty && rows.every((row) => _selectedIds.contains(row.id));
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
              child: MenuAnchor(
                style: const MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    AppTheme.backgroundColor,
                  ),
                  surfaceTintColor: WidgetStatePropertyAll(
                    AppTheme.backgroundColor,
                  ),
                  side: WidgetStatePropertyAll(
                    BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                menuChildren: [
                  MenuItemButton(
                    style: _menuItemStyle(),
                    leadingIcon: const Icon(
                      Icons.view_column_rounded,
                      size: 16,
                    ),
                    onPressed: _showCustomizeColumnsDialog,
                    child: const Text('Customize Columns'),
                  ),
                  MenuItemButton(
                    style: _menuItemStyle(),
                    leadingIcon: const Icon(LucideIcons.wrapText, size: 14),
                    onPressed: () {
                      setState(() => _clipText = !_clipText);
                      _persistCurrentViewPreferences();
                    },
                    child: const Text('Clip Text'),
                  ),
                ],
                builder: (context, controller, child) {
                  return InkWell(
                    onTap: () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.slidersHorizontal,
                        size: 14,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  );
                },
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
          for (final column in _visibleColumns)
            _hCell(column.label, column.width),
        ],
      ),
    );
  }

  Widget _buildDataRow(StockTransfer row) {
    final status = row.status.trim().toLowerCase();
    final statusColor = switch (status) {
      'received' || 'transferred' => AppTheme.successDark,
      'in_transit' => AppTheme.primaryBlue,
      'cancelled' => AppTheme.errorRedDark,
      _ => AppTheme.textPrimary,
    };

    final transferNumber = (row.transferNumber ?? '').trim().isEmpty
        ? '-'
        : row.transferNumber!.trim();

    return Container(
      constraints: BoxConstraints(minHeight: _clipText ? 60 : 72),
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
          for (final column in _visibleColumns)
            _buildDataCellForColumn(
              column,
              row,
              transferNumber: transferNumber,
              statusColor: statusColor,
            ),
        ],
      ),
    );
  }

  Widget _buildDataCellForColumn(
    _TransferListColumn column,
    StockTransfer row, {
    required String transferNumber,
    required Color statusColor,
  }) {
    switch (column.id) {
      case _colDate:
        return _dCell(_formatDate(row.transferDate), column.width);
      case _colTransferOrder:
        return _dLinkCell(transferNumber, column.width, row.id);
      case _colReason:
        return _dCell(
          (row.notes ?? '').trim().isEmpty ? '-' : row.notes!.trim(),
          column.width,
        );
      case _colStatus:
        return _dCell(
          _statusText(row.status.trim().toLowerCase()),
          column.width,
          color: statusColor,
        );
      case _colQuantity:
        return _dCell(_formatQty(row), column.width);
      case _colSourceLocation:
        return _dCell(row.fromWarehouseName, column.width);
      case _colDestinationLocation:
        return _dCell(row.toWarehouseName, column.width);
      case _colCreatedBy:
        return _dCell(
          (row.initiatedBy ?? '').trim().isEmpty ? '-' : row.initiatedBy!,
          column.width,
        );
      case _colCreatedTime:
        return _dCell(_formatDateTime(row.createdAt), column.width);
      case _colLastModifiedBy:
        return _dCell(
          (row.receivedBy ?? row.initiatedBy ?? '').trim().isEmpty
              ? '-'
              : (row.receivedBy ?? row.initiatedBy)!,
          column.width,
        );
      case _colLastModifiedTime:
        return _dCell(_formatDateTime(row.updatedAt), column.width);
      case _colQuantityTransferred:
        return _dCell(_formatTransferredQty(row), column.width);
      default:
        return _dCell('-', column.width);
    }
  }

  Widget _hCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _dCell(String text, double width, {Color? color}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          maxLines: _clipText ? 2 : null,
          overflow: _clipText ? TextOverflow.ellipsis : TextOverflow.visible,
          style: TextStyle(
            fontSize: 13,
            color: color ?? AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _dLinkCell(String text, double width, String transferId) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: InkWell(
          onTap: () =>
              context.go('/$_orgId/inventory/transfer-orders/$transferId'),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    status = status.trim().toLowerCase();
    switch (status) {
      case 'received':
      case 'transferred':
        return AppTheme.successDark;
      case 'in_transit':
        return AppTheme.primaryBlueDark;
      case 'partial_transferred':
        return AppTheme.warningOrange;
      case 'draft':
        return AppTheme.textSecondary;
      case 'cancelled':
        return AppTheme.errorRed;
      default:
        return AppTheme.textPrimary;
    }
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
      return const Center(child: Text('No transfer orders found.'));
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final selected = row.id == widget.id;
        final transferNumber = (row.transferNumber ?? '-').trim();
        final totalQty =
            row.totalQuantity ??
            row.items.fold<double>(
              0,
              (sum, item) => sum + item.transferredQuantity,
            );

        return InkWell(
          onTap: () =>
              context.go('/$_orgId/inventory/transfer-orders/${row.id}'),
          child: Container(
            color: selected ? AppTheme.bgHover : AppTheme.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transferNumber.isEmpty ? '-' : transferNumber,
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.primaryBlueDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      totalQty.toStringAsFixed(2),
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _statusText(
                        row.status.trim().toLowerCase(),
                      ).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(row.status),
                      ),
                    ),
                    Text(
                      _formatDate(row.transferDate),
                      style: AppTheme.metaHelper,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${row.fromWarehouseName} ➔ ${row.toWarehouseName}',
                  style: AppTheme.metaHelper.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleAll(List<StockTransfer> rows) {
    setState(() {
      final allSelected =
          rows.isNotEmpty && rows.every((row) => _selectedIds.contains(row.id));
      if (allSelected) {
        _selectedIds.removeAll(rows.map((row) => row.id));
      } else {
        _selectedIds.addAll(rows.map((row) => row.id));
      }
    });
  }

  ButtonStyle _menuItemStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return AppTheme.primaryBlue;
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return AppTheme.backgroundColor;
        }
        return AppTheme.textPrimary;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed)) {
          return AppTheme.backgroundColor;
        }
        return AppTheme.primaryBlue;
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _buildMoreActionsMenu() {
    final menuStyle = _menuItemStyle();
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppTheme.backgroundColor),
        surfaceTintColor: WidgetStatePropertyAll(AppTheme.backgroundColor),
        side: WidgetStatePropertyAll(BorderSide(color: AppTheme.borderColor)),
      ),
      menuChildren: [
        SubmenuButton(
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(AppTheme.backgroundColor),
            surfaceTintColor: WidgetStatePropertyAll(AppTheme.backgroundColor),
          ),
          style: menuStyle,
          leadingIcon: const Icon(LucideIcons.arrowUpDown, size: 14),
          child: const Text('Sort by'),
          menuChildren: [
            MenuItemButton(
              style: menuStyle,
              onPressed: () => _setSortField(_TransferSortField.date),
              trailingIcon: _sortField == _TransferSortField.date
                  ? Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 14,
                    )
                  : null,
              child: const Text('Date'),
            ),
            MenuItemButton(
              style: menuStyle,
              onPressed: () => _setSortField(_TransferSortField.createdTime),
              trailingIcon: _sortField == _TransferSortField.createdTime
                  ? Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 14,
                    )
                  : null,
              child: const Text('Created Time'),
            ),
            MenuItemButton(
              style: menuStyle,
              onPressed: () =>
                  _setSortField(_TransferSortField.lastModifiedTime),
              trailingIcon: _sortField == _TransferSortField.lastModifiedTime
                  ? Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 14,
                    )
                  : null,
              child: const Text('Last Modified Time'),
            ),
          ],
        ),
        MenuItemButton(
          style: menuStyle,
          leadingIcon: const Icon(LucideIcons.download, size: 14),
          onPressed: _importTransferOrdersFromFile,
          child: const Text('Import Transfer Order'),
        ),
        MenuItemButton(
          style: menuStyle,
          leadingIcon: const Icon(LucideIcons.upload, size: 14),
          onPressed: _exportTransferOrders,
          child: const Text('Export Transfer Order'),
        ),
        MenuItemButton(
          style: menuStyle,
          leadingIcon: const Icon(LucideIcons.refreshCcw, size: 14),
          onPressed: () => _loadRows(forceRefresh: true),
          child: const Text('Refresh List'),
        ),
      ],
      builder: (context, controller, child) {
        return SizedBox(
          width: 30,
          height: 30,
          child: TextButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: AppTheme.bgDisabled,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: const Icon(
              LucideIcons.moreHorizontal,
              size: 15,
              color: AppTheme.textSecondary,
            ),
          ),
        );
      },
    );
  }

  void _setSortField(_TransferSortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
    _persistCurrentViewPreferences();
  }

  void _showCustomizeColumnsDialog() {
    final tempVisibleColumns = Set<String>.from(_visibleColumnIds);
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
                            onTap: column.locked
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
                                    onChanged: column.locked
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
                                  if (column.locked)
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
                                _visibleColumnIds
                                  ..clear()
                                  ..addAll(tempVisibleColumns);
                              });
                              _persistCurrentViewPreferences();
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

  Future<void> _promptNewCustomView() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: EdgeInsets.zero,
          backgroundColor: AppTheme.backgroundColor,
          surfaceTintColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  child: Row(
                    children: [
                      Text(
                        'New Custom View',
                        style: AppTheme.sectionHeader.copyWith(fontSize: 18),
                      ),
                      const Spacer(),
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
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Text(
                    'Name',
                    style: AppTheme.metaHelper.copyWith(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Transfer Orders - In Transit',
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
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
                        onPressed: () => Navigator.of(
                          dialogContext,
                        ).pop(controller.text.trim()),
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
    controller.dispose();
    if (result == null || result.trim().isEmpty) return;
    await _saveCurrentAsCustomView(result);
  }

  Future<void> _exportTransferOrders() async {
    final rows = _filteredRows;
    if (rows.isEmpty) {
      ZerpaiToast.info(context, 'No transfer orders available to export');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln(
      <String>[
        'transfer_number',
        'from_warehouse_id',
        'from_warehouse_name',
        'to_warehouse_id',
        'to_warehouse_name',
        'transfer_date',
        'expected_delivery_date',
        'status',
        'reference',
        'notes',
        'initiated_by',
        'received_by',
        'product_id',
        'product_code',
        'product_name',
        'quantity',
        'transferred_quantity',
        'received_quantity',
        'uom',
        'batch_number',
        'expiry_date',
      ].join(','),
    );

    for (final row in rows) {
      final items = row.items.isEmpty
          ? <StockTransferItem?>[null]
          : row.items.cast<StockTransferItem?>();
      for (final item in items) {
        buffer.writeln(
          <String>[
            _csvEscape(row.transferNumber ?? ''),
            _csvEscape(row.fromWarehouseId),
            _csvEscape(row.fromWarehouseName),
            _csvEscape(row.toWarehouseId),
            _csvEscape(row.toWarehouseName),
            _csvEscape(row.transferDate.toIso8601String()),
            _csvEscape(row.expectedDeliveryDate?.toIso8601String() ?? ''),
            _csvEscape(row.status),
            _csvEscape(row.reference ?? ''),
            _csvEscape(row.notes ?? ''),
            _csvEscape(row.initiatedBy ?? ''),
            _csvEscape(row.receivedBy ?? ''),
            _csvEscape(item?.productId ?? ''),
            _csvEscape(item?.productCode ?? ''),
            _csvEscape(item?.productName ?? ''),
            _csvEscape(item?.quantity.toString() ?? ''),
            _csvEscape(item?.transferredQuantity.toString() ?? ''),
            _csvEscape(item?.receivedQuantity.toString() ?? ''),
            _csvEscape(item?.uom ?? ''),
            _csvEscape(item?.batchNumber ?? ''),
            _csvEscape(item?.expiryDate?.toIso8601String() ?? ''),
          ].join(','),
        );
      }
    }

    final fileName =
        'transfer_orders_${DateTime.now().millisecondsSinceEpoch}.csv';
    final csv = buffer.toString();
    try {
      final anchor =
          import_web.document.createElement('a')
              as import_web.HTMLAnchorElement;
      anchor.href = 'data:text/csv;charset=utf-8,${Uri.encodeComponent(csv)}';
      anchor.download = fileName;
      anchor.click();
      if (mounted) {
        ZerpaiToast.success(context, 'Transfer orders exported');
      }
    } catch (_) {
      if (mounted) {
        ZerpaiToast.error(context, 'Unable to export transfer orders');
      }
    }
  }

  Future<void> _importTransferOrdersFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['csv', 'json'],
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Unable to read the selected file');
      return;
    }

    final extension = (file.extension ?? '').toLowerCase();
    try {
      final drafts = extension == 'json'
          ? _parseTransferJsonImport(bytes)
          : _parseTransferCsvImport(bytes);
      if (drafts.isEmpty) {
        if (!mounted) return;
        ZerpaiToast.info(
          context,
          'No transferable records were found in the file',
        );
        return;
      }

      int successCount = 0;
      final List<String> failures = <String>[];
      for (final draft in drafts) {
        try {
          await _repository.createTransfer(draft);
          successCount++;
        } catch (error) {
          failures.add(error.toString());
        }
      }

      if (successCount > 0) {
        await _loadRows(forceRefresh: true);
      }
      if (!mounted) return;
      if (successCount > 0 && failures.isEmpty) {
        ZerpaiToast.success(
          context,
          '$successCount transfer order${successCount == 1 ? '' : 's'} imported',
        );
      } else if (successCount > 0) {
        ZerpaiToast.info(
          context,
          '$successCount imported, ${failures.length} failed',
        );
      } else {
        ZerpaiToast.error(
          context,
          failures.isEmpty ? 'Import failed' : failures.first,
        );
      }
    } catch (error) {
      if (!mounted) return;
      ZerpaiToast.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  List<StockTransfer> _parseTransferJsonImport(Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    final rows = decoded is List
        ? decoded
        : decoded is Map<String, dynamic> && decoded['data'] is List
        ? decoded['data'] as List<dynamic>
        : null;
    if (rows == null) {
      throw Exception('JSON import must be a list of transfer orders');
    }
    return rows
        .map(
          (row) =>
              StockTransfer.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  }

  List<StockTransfer> _parseTransferCsvImport(Uint8List bytes) {
    final content = utf8.decode(bytes);
    final lines = content
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (lines.length < 2) {
      throw Exception(
        'CSV import needs a header row and at least one item row',
      );
    }

    final headers = _splitCsvLine(
      lines.first,
    ).map((value) => value.trim().toLowerCase()).toList(growable: false);
    final Map<String, List<Map<String, String>>> grouped =
        <String, List<Map<String, String>>>{};

    for (final line in lines.skip(1)) {
      final cells = _splitCsvLine(line);
      final Map<String, String> row = <String, String>{};
      for (int i = 0; i < headers.length; i++) {
        row[headers[i]] = i < cells.length ? cells[i].trim() : '';
      }
      final groupKey = row['transfer_number']?.trim().isNotEmpty == true
          ? row['transfer_number']!.trim()
          : '${row['from_warehouse_id']}-${row['to_warehouse_id']}-${grouped.length}';
      grouped.putIfAbsent(groupKey, () => <Map<String, String>>[]).add(row);
    }

    final now = DateTime.now();
    return grouped.entries
        .map((entry) {
          final first = entry.value.first;
          final fromWarehouseId = _requiredImportValue(
            first,
            'from_warehouse_id',
          );
          final fromWarehouseName = _requiredImportValue(
            first,
            'from_warehouse_name',
          );
          final toWarehouseId = _requiredImportValue(first, 'to_warehouse_id');
          final toWarehouseName = _requiredImportValue(
            first,
            'to_warehouse_name',
          );

          final items = entry.value
              .map((row) {
                return StockTransferItem(
                  productId: _requiredImportValue(row, 'product_id'),
                  productCode: _nullableImportValue(row, 'product_code'),
                  productName: _nullableImportValue(row, 'product_name'),
                  quantity:
                      double.tryParse(_requiredImportValue(row, 'quantity')) ??
                      0,
                  transferredQuantity:
                      double.tryParse(
                        _nullableImportValue(row, 'transferred_quantity') ??
                            '0',
                      ) ??
                      0,
                  receivedQuantity:
                      double.tryParse(
                        _nullableImportValue(row, 'received_quantity') ?? '0',
                      ) ??
                      0,
                  uom: _nullableImportValue(row, 'uom'),
                  batchNumber: _nullableImportValue(row, 'batch_number'),
                  expiryDate: _parseImportDate(
                    _nullableImportValue(row, 'expiry_date'),
                  ),
                  notes: _nullableImportValue(row, 'item_notes'),
                );
              })
              .toList(growable: false);

          return StockTransfer(
            id: _uuid.v4(),
            transferNumber: _nullableImportValue(first, 'transfer_number'),
            fromWarehouseId: fromWarehouseId,
            fromWarehouseName: fromWarehouseName,
            toWarehouseId: toWarehouseId,
            toWarehouseName: toWarehouseName,
            transferDate: _parseImportDate(first['transfer_date']) ?? now,
            expectedDeliveryDate: _parseImportDate(
              first['expected_delivery_date'],
            ),
            status: (_nullableImportValue(first, 'status') ?? 'draft')
                .toLowerCase(),
            items: items,
            reference: _nullableImportValue(first, 'reference'),
            notes: _nullableImportValue(first, 'notes'),
            initiatedBy: _nullableImportValue(first, 'initiated_by'),
            receivedBy: _nullableImportValue(first, 'received_by'),
            createdAt: now,
            updatedAt: now,
          );
        })
        .toList(growable: false);
  }

  List<String> _splitCsvLine(String line) {
    final List<String> values = <String>[];
    final StringBuffer current = StringBuffer();
    bool insideQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (char == ',' && !insideQuotes) {
        values.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    values.add(current.toString());
    return values;
  }

  String _requiredImportValue(Map<String, String> row, String key) {
    final value = (row[key] ?? '').trim();
    if (value.isEmpty) {
      throw Exception('Import file is missing required column value: $key');
    }
    return value;
  }

  String? _nullableImportValue(Map<String, String> row, String key) {
    final value = (row[key] ?? '').trim();
    return value.isEmpty ? null : value;
  }

  DateTime? _parseImportDate(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    final parts = raw.split('-');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  String _csvEscape(String value) {
    final normalized = value.replaceAll('"', '""');
    return '"$normalized"';
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d-$m-$y';
  }

  String _formatDateTime(DateTime dt) {
    final d = _formatDate(dt);
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final hh = hour12.toString().padLeft(2, '0');
    return '$d $hh:$minute $amPm';
  }

  String _statusText(String status) {
    switch (status) {
      case 'in_transit':
        return 'In Transit';
      case 'received':
      case 'transferred':
        return 'Transferred';
      case 'partial_transferred':
        return 'Partially Transferred';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Void';
      case 'draft':
        return 'Draft';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  String _formatQty(StockTransfer row) {
    double total = 0;
    for (final item in row.items) {
      total += item.quantity;
    }
    return total.toStringAsFixed(2);
  }

  String _formatTransferredQty(StockTransfer row) {
    double total = 0;
    for (final item in row.items) {
      total += item.transferredQuantity;
    }
    return total.toStringAsFixed(2);
  }
}

class _TransferOrderDetailPanel extends StatefulWidget {
  const _TransferOrderDetailPanel({
    required this.id,
    required this.repository,
    required this.onClose,
    required this.onRefreshList,
  });

  final String id;
  final TransfersRepository repository;
  final VoidCallback onClose;
  final VoidCallback onRefreshList;

  @override
  State<_TransferOrderDetailPanel> createState() =>
      _TransferOrderDetailPanelState();
}

class _TransferOrderDetailPanelState extends State<_TransferOrderDetailPanel> {
  bool _isLoading = true;
  bool _showPdfView = false;
  String? _error;
  StockTransfer? _transfer;
  final WarehouseRepository _warehouseRepository = WarehouseRepositoryImpl();
  Map<String, Warehouse> _warehousesById = const <String, Warehouse>{};
  String? _orgId;
  bool _didInitialDependencyLoad = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resolvedOrgId = GoRouterState.of(context).pathParameters['orgSystemId'];
    if (resolvedOrgId == null || resolvedOrgId.trim().isEmpty) {
      return;
    }

    final orgChanged = _orgId != resolvedOrgId;
    _orgId = resolvedOrgId;
    if (!_didInitialDependencyLoad || orgChanged) {
      _didInitialDependencyLoad = true;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant _TransferOrderDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _load();
    }
  }

  Future<void> _load() async {
    final orgId = _orgId;
    if (orgId == null || orgId.trim().isEmpty) {
      return;
    }
    AppLogger.debug(
      '🚀 _TransferOrderDetailPanel._load() triggered for ID: ${widget.id}',
      module: 'transfers_ui',
    );
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      AppLogger.debug(
        '📡 Requesting detail from repository...',
        module: 'transfers_ui',
      );
      final results = await Future.wait([
        widget.repository.getTransfer(widget.id),
        _warehouseRepository.getWarehouses(forceRefresh: true, orgId: orgId),
      ]);
      final data = results[0] as StockTransfer?;
      final warehouses = results[1] as List<Warehouse>;
      if (!mounted) return;
      setState(() {
        _transfer = data;
        _warehousesById = {
          for (final warehouse in warehouses)
            if (warehouse.id.trim().isNotEmpty) warehouse.id: warehouse,
        };
        _isLoading = false;
      });
      AppLogger.debug('✅ Detail loaded successfully', module: 'transfers_ui');
    } catch (e) {
      AppLogger.error('❌ Detail load failed', error: e, module: 'transfers_ui');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<String> _warehouseAddressLines(String warehouseId) {
    final raw = _warehousesById[warehouseId.trim()]?.address?.trim() ?? '';
    if (raw.isEmpty) {
      return const <String>['—'];
    }

    final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final parts = normalized
        .split(RegExp(r'[\n,]'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return const <String>['—'];
    }
    return parts;
  }

  List<String> _warehouseAddressLinesForDisplay(String warehouseId) {
    final lines = _warehouseAddressLines(warehouseId);
    if (lines.length == 1 && (lines.first == '—' || lines.first == '-')) {
      return const <String>[];
    }
    return lines;
  }

  String _resolveWarehouseDisplayName(String preferredName, String warehouseId) {
    final direct = preferredName.trim();
    if (direct.isNotEmpty && direct != '-' && direct != '—') {
      return direct;
    }

    final lookup = _warehousesById[warehouseId.trim()]?.name.trim() ?? '';
    if (lookup.isNotEmpty) {
      return lookup;
    }

    return '-';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: ZTableSkeleton(rows: 8, columns: 2),
      );
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    final transfer = _transfer;
    if (transfer == null) {
      return const Center(child: Text('Transfer order not found.'));
    }

    final status = transfer.status.toUpperCase();
    final statusColor = status == 'RECEIVED' || status == 'TRANSFERRED'
        ? AppTheme.successDark
        : AppTheme.primaryBlueDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                (transfer.transferNumber ?? 'Transfer Order').trim(),
                style: AppTheme.sectionHeader,
              ),
              const Spacer(),
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
              if (status != 'RECEIVED')
                _buildHeaderActionButton(
                  'Mark as Received',
                  LucideIcons.checkCircle2,
                  () => _handleMarkAsReceived(transfer),
                ),
              if (status != 'RECEIVED') const SizedBox(width: 10),
              _buildHeaderActionButton(
                'Edit',
                LucideIcons.edit3,
                () => _handleEdit(transfer),
              ),
              const SizedBox(width: 10),
              _buildPdfPrintMenu(),
              const SizedBox(width: 10),
              _buildDeleteButton(transfer),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        Expanded(
          child: DocumentViewModeSwitcher(
            showPdfView: _showPdfView,
            onChanged: (val) => setState(() => _showPdfView = val),
            normalView: _buildNormalDetail(transfer),
            pdfView: ZerpaiDocumentView(
              documentType: 'TRANSFER ORDER',
              documentNumber: (transfer.transferNumber ?? 'TO-').trim(),
              status: status,
              statusColor: statusColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPdfMetaSection(transfer),
                  const SizedBox(height: 32),
                  _buildPdfLocationSection(transfer),
                  const SizedBox(height: 32),
                  Expanded(child: _itemsTablePdf(transfer)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton(
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

  void _handleMarkAsReceived(StockTransfer transfer) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Mark as Received',
      message: 'Are you sure you want to mark this transfer order as received?',
      confirmLabel: 'Receive',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.success,
    );
    if (!confirmed) return;

    try {
      final currentStatus = transfer.status.trim().toUpperCase();
      if (currentStatus == 'DRAFT') {
        await widget.repository.initiateTransfer(transfer.id);
      }
      await widget.repository.approveTransfer(transfer.id);
      ZerpaiToast.success(context, 'Transfer marked as received');
      widget.onRefreshList();
      _load();
    } catch (e) {
      ZerpaiToast.error(context, 'Failed to mark transfer as received');
    }
  }

  void _handleEdit(StockTransfer transfer) {
    final status = transfer.status.trim().toUpperCase();
    if (status != 'DRAFT') {
      ZerpaiToast.info(context, 'Only draft transfer orders can be edited');
      return;
    }
    context.goNamed(
      AppRoutes.transferOrdersEdit,
      pathParameters: <String, String>{'id': transfer.id},
    );
  }

  Widget _buildPdfMetaSection(StockTransfer transfer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Date : ${DateFormat('dd-MM-yyyy').format(transfer.transferDate)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPdfLocationSection(StockTransfer transfer) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Source Location',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _resolveWarehouseDisplayName(
                  transfer.fromWarehouseName,
                  transfer.fromWarehouseId,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
              ..._warehouseAddressLinesForDisplay(transfer.fromWarehouseId).map(
                (line) => Text(
                  line,
                  style: const TextStyle(fontSize: 11, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Destination Location',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _resolveWarehouseDisplayName(
                  transfer.toWarehouseName,
                  transfer.toWarehouseId,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
              ..._warehouseAddressLinesForDisplay(transfer.toWarehouseId).map(
                (line) => Text(
                  line,
                  style: const TextStyle(fontSize: 11, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPdfPrintMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'pdf':
            setState(() => _showPdfView = true);
            break;
          case 'print':
            try {
              import_web.window.print();
            } catch (_) {}
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'pdf',
          child: Row(
            children: [
              Icon(LucideIcons.fileText, size: 14),
              SizedBox(width: 8),
              Text('Export as PDF'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
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
            Icon(LucideIcons.chevronDown, size: 12, color: AppTheme.textPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(StockTransfer transfer) {
    return SizedBox(
      height: 30,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showZerpaiConfirmationDialog(
            context,
            title: 'Delete Transfer Order',
            message:
                'This will permanently delete ${transfer.transferNumber ?? 'this transfer order'}.',
            confirmLabel: 'Delete',
            cancelLabel: 'Cancel',
            variant: ZerpaiConfirmationVariant.danger,
          );
          if (!confirmed) return;
          await widget.repository.deleteTransfer(transfer.id);
          if (!mounted) return;
          ZerpaiToast.success(context, 'Transfer order deleted');
          widget.onClose();
        },
        icon: const Icon(LucideIcons.trash2, size: 14),
        label: const Text(
          'Delete',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _buildNormalDetail(StockTransfer transfer) {
    final status = transfer.status.toUpperCase();
    final statusColor = status == 'RECEIVED' || status == 'TRANSFERRED'
        ? AppTheme.successDark
        : AppTheme.primaryBlueDark;
    final sourceName = _resolveWarehouseDisplayName(
      transfer.fromWarehouseName,
      transfer.fromWarehouseId,
    );
    final destinationName = _resolveWarehouseDisplayName(
      transfer.toWarehouseName,
      transfer.toWarehouseId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: AppTheme.borderColor),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRANSFER ORDER',
                  style: AppTheme.sectionHeader.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Transfer Order# ${transfer.transferNumber ?? "TO-"}',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: OverviewSectionCard(
                        entries: [
                          OverviewEntry(
                            label: 'Date',
                            value: DateFormat(
                              'dd-MM-yyyy',
                            ).format(transfer.transferDate),
                          ),
                          OverviewEntry(
                            label: 'Created Time',
                            value: DateFormat(
                              'dd-MM-yyyy hh:mm a',
                            ).format(transfer.createdAt),
                          ),
                          OverviewEntry(
                            label: 'Last Modified Time',
                            value: DateFormat(
                              'dd-MM-yyyy hh:mm a',
                            ).format(transfer.updatedAt),
                          ),
                          OverviewEntry(label: 'Source Location', value: sourceName),
                          OverviewEntry(
                            label: 'Destination Location',
                            value: destinationName,
                          ),
                          OverviewEntry(label: 'Status', value: status),
                          OverviewEntry(
                            label: 'Created By',
                            value: transfer.initiatedBy ?? 'zabnixprivatelimited',
                          ),
                          const OverviewEntry(
                            label: 'Place of Supply',
                            value: 'Kerala(32)',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    _summaryTotalCard(
                      'Total',
                      NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹',
                        decimalDigits: 2,
                      ).format(_transferTotalAmount(transfer)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildItemsTable(transfer),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _transferTotalAmount(StockTransfer transfer) {
    double total = 0;
    for (final item in transfer.items) {
      total += item.amount;
    }
    return total;
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

  Widget _buildItemsTable(StockTransfer transfer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.borderColor),
              bottom: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'ITEMS & DESCRIPTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'HSN/SAC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'QUANTITY TRANSFERRED',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'COST PRICE',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'AMOUNT',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (transfer.items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No items found.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        for (final item in transfer.items)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName ?? 'Unknown Item',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlueDark,
                        ),
                      ),
                      if (item.productCode != null)
                        Text(
                          item.productCode!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    item.hsnSac ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    item.transferredQuantity.toStringAsFixed(2),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    (item.rate ?? 0).toStringAsFixed(2),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    item.amount.toStringAsFixed(2),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _itemsTablePdf(StockTransfer transfer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZerpaiDocumentTableHeader(
          children: [
            ZerpaiDocumentHeaderCell('ITEMS & DESCRIPTION', flex: 3),
            ZerpaiDocumentHeaderCell('HSN/SAC', flex: 1),
            ZerpaiDocumentHeaderCell(
              'QUANTITY',
              flex: 1,
              align: TextAlign.right,
            ),
            ZerpaiDocumentHeaderCell(
              'COST PRICE',
              flex: 1,
              align: TextAlign.right,
            ),
            ZerpaiDocumentHeaderCell('AMOUNT', flex: 1, align: TextAlign.right),
          ],
        ),
        if (transfer.items.isEmpty)
          const ZerpaiDocumentTableRow(
            children: [ZerpaiDocumentDataCell('No items found.', flex: 1)],
          ),
        for (final item in transfer.items)
          ZerpaiDocumentTableRow(
            children: [
              ZerpaiDocumentDataCell(
                item.productName ?? item.productCode ?? item.productId,
                flex: 3,
              ),
              const ZerpaiDocumentDataCell('-', flex: 1),
              ZerpaiDocumentDataCell(
                item.transferredQuantity.toStringAsFixed(2),
                flex: 1,
                align: TextAlign.right,
              ),
              const ZerpaiDocumentDataCell(
                '0.00',
                flex: 1,
                align: TextAlign.right,
              ),
              const ZerpaiDocumentDataCell(
                '0.00',
                flex: 1,
                align: TextAlign.right,
              ),
            ],
          ),
      ],
    );
  }
}
