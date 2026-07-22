import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/workflow/transaction_status_normalizer.dart';
import 'package:zerpai_erp/core/workflow/transaction_status_transition_guard.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart'
    as accountant;
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/accountant/repositories/accountant_repository.dart';
import 'package:zerpai_erp/modules/inventory/adjustments/providers/inventory_adjustments_provider.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_model.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_reason_model.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/presentation/widgets/item_details_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/warehouse_change_confirm_dialog.dart';
import 'package:zerpai_erp/shared/widgets/buttons/z_split_action_menu_button.dart';
import 'package:zerpai_erp/shared/models/account_node.dart' as shared;
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/sections/attachment_section.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

// const Color _textPrimary = Color(0xFF1F2937); // Removed unused declaration

class InventoryAdjustmentsCreateScreen extends ConsumerStatefulWidget {
  final InventoryAdjustment? initialAdjustment;
  final String? initialAdjustmentId;
  final String? returnToPath;
  final bool isClone;

  const InventoryAdjustmentsCreateScreen({
    super.key,
    this.initialAdjustment,
    this.initialAdjustmentId,
    this.returnToPath,
    this.isClone = false,
  });

  @override
  ConsumerState<InventoryAdjustmentsCreateScreen> createState() =>
      _InventoryAdjustmentsCreateScreenState();
}

class _InventoryAdjustmentsCreateScreenState
    extends ConsumerState<InventoryAdjustmentsCreateScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _dateFieldKey = GlobalKey();
  final TextEditingController _dateController = TextEditingController();
  final FocusNode _dateFocusNode = FocusNode();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _itemDescriptionController =
      TextEditingController();
  final TextEditingController _adjustedController = TextEditingController();
  final TextEditingController _secondaryItemDescriptionController =
      TextEditingController();
  final TextEditingController _secondaryAdjustedController =
      TextEditingController();
  final ApiClient _apiClient = ApiClient();
  final LayerLink _bulkActionsLayerLink = LayerLink();
  final List<LayerLink> _reportingTagLayerLinks = <LayerLink>[
    LayerLink(),
    LayerLink(),
  ];
  final List<LayerLink> _rowActionsLayerLinks = <LayerLink>[
    LayerLink(),
    LayerLink(),
  ];
  final List<LayerLink> _costPriceLayerLinks = <LayerLink>[
    LayerLink(),
    LayerLink(),
  ];
  OverlayEntry? _bulkActionsOverlay;
  OverlayEntry? _rowActionsOverlay;
  OverlayEntry? _reportingTagsOverlay;
  OverlayEntry? _costPriceOverlay;
  String? _hoveredBulkAction;
  String? _hoveredRowAction;
  int? _hoveredItemRowIndex;
  int? _openRowActionsRowIndex;
  int? _openReportingTagsRowIndex;
  int? _openCostPriceRowIndex;

  DateTime _adjustmentDate = DateTime.now();
  String _mode = 'quantity';
  String? _selectedAccountId;
  String? _selectedReason;
  Warehouse? _selectedWarehouse;
  _ProductOption? _selectedProduct;
  _ProductOption? _secondarySelectedProduct;
  double _quantityAvailable = 0;
  double _secondaryQuantityAvailable = 0;
  double? _currentValueBaseline;
  double? _secondaryCurrentValueBaseline;
  bool _saving = false;
  List<PlatformFile> _attachedFiles = [];
  bool _loadingAccounts = false;
  bool _loadingProducts = false;
  bool _showAllAdditionalInformation = true;
  bool _bulkSelectionMode = false;
  String? _editingSourceId;
  String _currentStatus = 'draft';

  List<shared.AccountNode> _accountNodes = const <shared.AccountNode>[];
  List<_ProductOption>? _productOptions = const <_ProductOption>[];
  final List<int> _rowOrder = <int>[0];
  int _nextRowId = 1;
  final List<bool> _selectedLineItems = <bool>[false];
  final Map<int, _ProductOption?> _extraSelectedProducts =
      <int, _ProductOption?>{};
  final Map<int, double> _extraQuantitiesAvailable = <int, double>{};
  final Map<int, double?> _extraCurrentValueBaselines = <int, double?>{};
  final Map<int, TextEditingController> _extraDescriptionControllers =
      <int, TextEditingController>{};
  final Map<int, TextEditingController> _extraAdjustedControllers =
      <int, TextEditingController>{};
  Map<int, TextEditingController>? _extraNewOnHandControllers;
  final Map<int, Map<String, String?>> _lineReportingTags =
      <int, Map<String, String?>>{0: <String, String?>{}};
  final Map<int, double?> _lineCostPrices = <int, double?>{};
  final Map<int, _AdjBatchDialogResult> _rowBatchResults =
      <int, _AdjBatchDialogResult>{};
  static const double _fieldWidth = 330;
  static const double _formLabelWidth = 180;
  static const double _tableWidth = 1048;
  static const Map<String, List<String>> _reportingTagOptions = {
    'Region': ['North', 'South', 'East', 'West'],
    'Department': ['Sales', 'Warehouse', 'Marketing', 'Admin'],
    'Project': ['Summer Sale', 'Stock Clearance', 'New Launch'],
  };

  final List<InventoryAdjustmentReason> _reasonOptions =
      <InventoryAdjustmentReason>[];
  bool _loadingReasons = false;

  @override
  void initState() {
    super.initState();
    final initialId = (widget.initialAdjustmentId ?? '').trim();
    if (widget.initialAdjustment != null) {
      _applyInitialAdjustment(widget.initialAdjustment!);
    }
    if (widget.initialAdjustment == null && initialId.isNotEmpty) {
      _loadInitialAdjustmentById(initialId);
    }
    _dateController.text = DateFormat('dd/MM/yyyy').format(_adjustmentDate);
    _dateFocusNode.addListener(_handleDateFocusChange);
    _loadAccounts();
    _loadInitialProducts();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    setState(() => _loadingReasons = true);
    try {
      final repo = ref.read(adjustmentsRepositoryProvider);
      final reasons = await repo.getAdjustmentReasons();
      if (!mounted) return;
      setState(() {
        _reasonOptions
          ..clear()
          ..addAll(reasons);
        if (_selectedReason != null &&
            !_reasonOptions.any((reason) => reason.name == _selectedReason)) {
          _selectedReason = _matchReasonOption(_selectedReason!);
        }
      });
    } finally {
      if (mounted) {
        setState(() => _loadingReasons = false);
      }
    }
  }

  List<String> get _reasonOptionLabels =>
      _reasonOptions.map((reason) => reason.name).toList();

  void _applyInitialAdjustment(InventoryAdjustment initial) {
    _editingSourceId = initial.id;
    _adjustmentDate = widget.isClone ? DateTime.now() : initial.adjustmentDate;
    _referenceController.text = widget.isClone
        ? ''
        : (initial.referenceNumber ?? '');
    _descriptionController.text = initial.notes ?? '';
    _selectedReason = _matchReasonOption(initial.reason);
    _mode = initial.adjustmentType.toLowerCase().contains('value')
        ? 'value'
        : 'quantity';
    _currentStatus = normalizeTransactionStatus(initial.status);
    _selectedAccountId = initial.accountId;

    if ((initial.warehouseId ?? '').trim().isNotEmpty ||
        (initial.warehouseName ?? '').trim().isNotEmpty) {
      _selectedWarehouse = Warehouse(
        id: (initial.warehouseId ?? '').trim(),
        name: (initial.warehouseName ?? '').trim().isNotEmpty
            ? initial.warehouseName!.trim()
            : 'Selected Warehouse',
      );
    }

    final seedItems = initial.items.isNotEmpty
        ? initial.items
        : <InventoryAdjustmentItem>[
            InventoryAdjustmentItem(
              id: 'seed_0',
              productId: initial.productId,
              quantityAdjusted: initial.quantityAdjusted,
              costPrice: initial.costPrice,
              batchId: null,
              batchReference: null,
            ),
          ];

    _rowOrder
      ..clear()
      ..addAll(List<int>.generate(seedItems.length, (i) => i));
    _nextRowId = seedItems.length;

    for (var i = 0; i < seedItems.length; i++) {
      final item = seedItems[i];
      final rowIndex = i;
      _ensureRowInfrastructure(rowIndex);
      _setSelectedProductForRow(
        rowIndex,
        _ProductOption(
          id: item.productId,
          name:
              item.productId == initial.productId &&
                  (initial.productName ?? '').trim().isNotEmpty
              ? initial.productName!.trim()
              : '',
          code: '',
          description: '',
          costPrice: item.costPrice,
          recentPrice: item.costPrice,
          trackBatches:
              item.batchId != null || item.batchAllocations.isNotEmpty,
        ),
      );
      _adjustedControllerForRow(rowIndex).text = _formatSignedQtyInput(
        item.quantityAdjusted,
      );
      _lineCostPrices[rowIndex] = item.costPrice;

      final batches =
          (item.batchAllocations.isNotEmpty
                  ? item.batchAllocations
                  : <InventoryAdjustmentBatchAllocation>[
                      InventoryAdjustmentBatchAllocation(
                        batchId: item.batchId,
                        batchReference: item.batchReference,
                        quantityIn: item.quantityAdjusted.abs(),
                        quantityOut: 0,
                      ),
                    ])
              .where(
                (b) =>
                    (b.batchId ?? '').trim().isNotEmpty ||
                    (b.batchReference ?? '').trim().isNotEmpty ||
                    b.quantityIn > 0 ||
                    b.quantityOut > 0,
              )
              .map(
                (b) => _AdjBatch(
                  batchId: (b.batchId ?? '').trim(),
                  batchReference: (b.batchReference ?? '').trim().isNotEmpty
                      ? b.batchReference!.trim()
                      : (b.batchId ?? '').trim(),
                  binId: b.binId,
                  quantity: b.quantityOut != 0
                      ? b.quantityOut.abs()
                      : b.quantityIn,
                  unitPack: (b.unitPack ?? '').trim().isEmpty
                      ? null
                      : b.unitPack!.trim(),
                  mrp: b.mrp,
                  expiryDate: b.expiryDate,
                  mfdDate: b.mfdDate,
                ),
              )
              .toList(growable: false);

      if (batches.isNotEmpty) {
        _rowBatchResults[rowIndex] = _AdjBatchDialogResult(
          batches: batches,
          totalQuantity: item.quantityAdjusted.abs(),
          overwriteLineItem: false,
        );
      }
    }

    _ensureTrailingBlankRowInState();
  }

  Future<void> _loadInitialAdjustmentById(String id) async {
    try {
      final repo = ref.read(adjustmentsRepositoryProvider);
      final loaded = await repo.getAdjustment(id);
      if (!mounted || loaded == null) return;
      setState(() {
        _applyInitialAdjustment(loaded);
        _dateController.text = DateFormat('dd/MM/yyyy').format(_adjustmentDate);
      });
    } catch (_) {
      // Keep create mode when edit prefill cannot be loaded.
    }
  }

  String? _matchReasonOption(String rawReason) {
    final normalized = rawReason.trim().toLowerCase().replaceAll('_', ' ');
    for (final option in _reasonOptions) {
      final name = option.name.trim().toLowerCase();
      if (name == normalized || name.contains(normalized)) return option.name;
    }
    return rawReason.trim().isEmpty ? null : rawReason.trim();
  }

  @override
  void dispose() {
    _hideBulkActionsMenu();
    _hideRowActionsMenu();
    _hideReportingTagsUnavailablePopover();
    _hideCostPricePopover();
    _dateFocusNode.removeListener(_handleDateFocusChange);
    _dateFocusNode.dispose();
    _dateController.dispose();
    _referenceController.dispose();
    _descriptionController.dispose();
    _itemDescriptionController.dispose();
    _adjustedController.dispose();
    _secondaryItemDescriptionController.dispose();
    _secondaryAdjustedController.dispose();
    for (final controller in _extraDescriptionControllers.values) {
      controller.dispose();
    }
    for (final controller in _extraAdjustedControllers.values) {
      controller.dispose();
    }
    for (final controller
        in (_extraNewOnHandControllers ?? const <int, TextEditingController>{})
            .values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    if (!mounted) return;
    setState(() => _loadingAccounts = true);
    try {
      final repoParsed = await _loadAccountsFromRepository();
      if (!mounted) return;
      if (kDebugMode) {
        print('InventoryAdjustments repo source: parsed=${repoParsed.length}');
      }

      Future<List<_AccountRow>> loadFrom(
        String path, {
        bool useCache = false,
      }) async {
        try {
          final response = await _apiClient.get(path, useCache: useCache);
          if (kDebugMode) {
            final data = response.data;
            print(
              'InventoryAdjustments source=$path cache=$useCache runtimeType=${data.runtimeType}',
            );
            if (data is List && data.isNotEmpty && data.first is Map) {
              print(
                'InventoryAdjustments source=$path firstRowKeys=${(data.first as Map).keys.join(',')}',
              );
            } else if (data is Map<String, dynamic>) {
              print(
                'InventoryAdjustments source=$path topLevelKeys=${data.keys.join(',')}',
              );
            }
          }
          return _parseAccountRows(response.data);
        } catch (e, st) {
          if (kDebugMode) {
            print('InventoryAdjustments source=$path cache=$useCache error=$e');
            print(st);
          }
          return const <_AccountRow>[];
        }
      }

      var parsed = repoParsed;

      if (parsed.isEmpty) {
        parsed = await loadFrom('accountant', useCache: false);
      }

      if (parsed.isEmpty) {
        parsed = await loadFrom('accountant', useCache: true);
      }
      if (parsed.isEmpty) {
        parsed = await loadFrom(
          '/products/lookups/accountant',
          useCache: false,
        );
      }
      if (parsed.isEmpty) {
        parsed = await loadFrom('/products/lookups/accountant', useCache: true);
      }

      var nodes = _buildAccountTypeTree(parsed);
      if (nodes.isEmpty && parsed.isNotEmpty) {
        final flatAccounts = [
          ...parsed,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        nodes = flatAccounts
            .map(
              (account) => shared.AccountNode(
                id: account.id,
                name: account.name,
                selectable: true,
              ),
            )
            .toList(growable: false);
      }
      final preferred = _findPreferredAccountId(nodes);
      if (kDebugMode) {
        print(
          'InventoryAdjustments accounts: parsed=${parsed.length}, roots=${nodes.length}, preferred=$preferred',
        );
        if (parsed.isNotEmpty) {
          print(
            'InventoryAdjustments account sample: ${parsed.take(5).map((e) => e.name).join(' | ')}',
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _accountNodes = nodes;
        _selectedAccountId = preferred;
      });
    } catch (e, st) {
      if (kDebugMode) {
        print('InventoryAdjustments _loadAccounts failed: $e');
        print(st);
      }
      if (!mounted) return;
      setState(() {
        _accountNodes = const <shared.AccountNode>[];
        _selectedAccountId = null;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingAccounts = false);
      }
    }
  }

  Future<List<_AccountRow>> _loadAccountsFromRepository() async {
    try {
      final repository = ref.read(accountantRepositoryProvider);
      final accounts = await repository.getAccounts(forceRefresh: true);
      if (accounts.isEmpty) return const <_AccountRow>[];

      final byId = <String, _AccountRow>{};

      void collect(accountant.AccountNode node) {
        final id = node.id.trim();
        final name = node.name.trim();
        if (id.isNotEmpty && name.isNotEmpty) {
          byId[id] = _AccountRow(
            id: id,
            name: name,
            parentId: node.parentId?.trim().isEmpty == true
                ? null
                : node.parentId?.trim(),
            accountType: node.accountType.trim().isEmpty
                ? 'Other'
                : node.accountType.trim(),
            accountGroup: node.accountGroup.trim().isEmpty
                ? 'Other'
                : node.accountGroup.trim(),
            isActive: node.isActive,
            isDeleted: node.isDeleted,
          );
        }
        for (final child in node.children) {
          collect(child);
        }
      }

      for (final account in accounts) {
        collect(account);
      }

      return byId.values
          .where((a) => a.isActive && !a.isDeleted)
          .toList(growable: false);
    } catch (e, st) {
      if (kDebugMode) {
        print('InventoryAdjustments repository load failed: $e');
        print(st);
      }
      return const <_AccountRow>[];
    }
  }

  List<_AccountRow> _parseAccountRows(dynamic payload) {
    final byId = <String, _AccountRow>{};
    if (kDebugMode) {
      print('InventoryAdjustments parse payloadType=${payload.runtimeType}');
    }
    for (final row in _extractAccountRows(payload)) {
      try {
        final parsed = _AccountRow.fromJson(row);
        if (parsed.id.isEmpty || parsed.name.isEmpty) continue;
        if (!parsed.isActive || parsed.isDeleted) continue;
        byId[parsed.id] = parsed;
      } catch (e) {
        if (kDebugMode) {
          print('InventoryAdjustments row parse skipped: $e');
        }
        continue;
      }
    }
    if (kDebugMode) {
      print('InventoryAdjustments parse result count=${byId.length}');
    }
    return byId.values.toList();
  }

  List<Map<String, dynamic>> _extractAccountRows(dynamic payload) {
    bool looksLikeAccountRow(Map<String, dynamic> row) {
      const accountSignals = <String>{
        'id',
        'user_account_name',
        'userAccountName',
        'account_name',
        'accountName',
        'system_account_name',
        'systemAccountName',
        'account_type',
        'accountType',
      };
      return row.keys.any(accountSignals.contains);
    }

    final flat = <Map<String, dynamic>>[];
    final seen = <String>{};

    void collect(dynamic node) {
      if (node is List) {
        for (final child in node) {
          collect(child);
        }
        return;
      }
      if (node is Map) {
        final mapped = Map<String, dynamic>.from(node);
        if (looksLikeAccountRow(mapped)) {
          final key = (mapped['id'] ?? mapped['name'] ?? mapped['account_name'])
              .toString();
          if (key.isNotEmpty && !seen.contains(key)) {
            flat.add(mapped);
            seen.add(key);
          }
        }
        for (final value in mapped.values) {
          if (value is List || value is Map) {
            collect(value);
          }
        }
      }
    }

    collect(payload);
    return flat;
  }

  Future<List<shared.AccountNode>> _searchAccounts(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return _accountNodes;
    return _filterAccountNodes(_accountNodes, q);
  }

  List<shared.AccountNode> _buildAccountTypeTree(List<_AccountRow> accounts) {
    if (accounts.isEmpty) return const <shared.AccountNode>[];

    final Map<String, _AccountRow> byId = <String, _AccountRow>{
      for (final a in accounts) a.id: a,
    };
    final Map<String, List<_AccountRow>> childrenByParent =
        <String, List<_AccountRow>>{};
    final Map<String, List<_AccountRow>> rootsByType =
        <String, List<_AccountRow>>{};

    for (final account in accounts) {
      final parentId = account.parentId;
      if (parentId != null && byId.containsKey(parentId)) {
        childrenByParent
            .putIfAbsent(parentId, () => <_AccountRow>[])
            .add(account);
        continue;
      }
      rootsByType
          .putIfAbsent(account.accountType, () => <_AccountRow>[])
          .add(account);
    }

    if (rootsByType.isEmpty) {
      for (final account in accounts) {
        rootsByType
            .putIfAbsent(account.accountType, () => <_AccountRow>[])
            .add(account);
      }
    }

    const groupOrder = <String>[
      'Assets',
      'Liabilities',
      'Equity',
      'Income',
      'Expenses',
    ];

    final sortedTypes = rootsByType.keys.toList()
      ..sort((a, b) {
        final ga = rootsByType[a]!.first.accountGroup;
        final gb = rootsByType[b]!.first.accountGroup;
        final ia = groupOrder.indexWhere(
          (g) => g.toLowerCase() == ga.toLowerCase(),
        );
        final ib = groupOrder.indexWhere(
          (g) => g.toLowerCase() == gb.toLowerCase(),
        );
        if (ia != -1 && ib != -1 && ia != ib) return ia.compareTo(ib);
        if (ia != -1 && ib == -1) return -1;
        if (ia == -1 && ib != -1) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    shared.AccountNode mapNode(_AccountRow row, Set<String> path) {
      if (path.contains(row.id)) {
        return shared.AccountNode(id: row.id, name: row.name, selectable: true);
      }

      final nextPath = <String>{...path, row.id};
      final children = <_AccountRow>[
        ...(childrenByParent[row.id] ?? const <_AccountRow>[]),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return shared.AccountNode(
        id: row.id,
        name: row.name,
        selectable: true,
        children: children.map((child) => mapNode(child, nextPath)).toList(),
      );
    }

    return sortedTypes.map((type) {
      final roots = <_AccountRow>[
        ...(rootsByType[type] ?? const <_AccountRow>[]),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return shared.AccountNode(
        id: '__account_type__${type.toLowerCase().replaceAll(' ', '_')}',
        name: type,
        selectable: false,
        children: roots.map((root) => mapNode(root, <String>{})).toList(),
      );
    }).toList();
  }

  List<shared.AccountNode> _filterAccountNodes(
    List<shared.AccountNode> nodes,
    String q,
  ) {
    final List<shared.AccountNode> filtered = <shared.AccountNode>[];
    for (final node in nodes) {
      final selfMatch = node.name.toLowerCase().contains(q);
      final childMatches = _filterAccountNodes(node.children, q);

      if (selfMatch || childMatches.isNotEmpty) {
        filtered.add(
          shared.AccountNode(
            id: node.id,
            name: node.name,
            selectable: node.selectable,
            children: childMatches,
          ),
        );
      }
    }
    return filtered;
  }

  String? _findPreferredAccountId(List<shared.AccountNode> nodes) {
    final all = <shared.AccountNode>[];
    void collect(List<shared.AccountNode> source) {
      for (final node in source) {
        if (node.selectable) all.add(node);
        if (node.children.isNotEmpty) collect(node.children);
      }
    }

    collect(nodes);
    if (all.isEmpty) return null;

    final cogs = all.firstWhere(
      (a) => a.name.trim().toLowerCase() == 'cost of goods sold',
      orElse: () => all.first,
    );
    return cogs.id;
  }

  Future<List<_ProductOption>> _searchProducts(String query) async {
    final q = query.trim();
    final localOptions = _productOptions ?? const <_ProductOption>[];
    if (q.isEmpty) return localOptions;
    if (q.length < 2) {
      final lower = q.toLowerCase();
      return localOptions.where((p) {
        return p.name.toLowerCase().contains(lower) ||
            p.code.toLowerCase().contains(lower);
      }).toList();
    }

    try {
      final response = await _apiClient.get(
        '/products/search',
        queryParameters: <String, dynamic>{'q': q, 'limit': 100},
      );
      final dynamic payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic>
                ? ((payload['items'] as List<dynamic>?) ??
                      (payload['data'] as List<dynamic>?) ??
                      const <dynamic>[])
                : const <dynamic>[]);

      final remote = rows
          .whereType<Map<String, dynamic>>()
          .map(_ProductOption.fromJson)
          .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
          .toList();

      if (remote.isNotEmpty) return remote;

      // Remote returned nothing — fall back to local filter
      final lower = q.toLowerCase();
      return localOptions.where((p) {
        return p.name.toLowerCase().contains(lower) ||
            p.code.toLowerCase().contains(lower);
      }).toList();
    } catch (_) {
      return localOptions;
    }
  }

  Future<void> _loadInitialProducts() async {
    if (!mounted) return;
    setState(() => _loadingProducts = true);
    try {
      final response = await _apiClient.get(
        '/products',
        queryParameters: <String, dynamic>{'limit': 200},
      );
      if (!mounted) return;
      final dynamic payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic>
                ? ((payload['items'] as List<dynamic>?) ??
                      (payload['data'] as List<dynamic>?) ??
                      const <dynamic>[])
                : const <dynamic>[]);

      final products = rows
          .whereType<Map<String, dynamic>>()
          .map(_ProductOption.fromJson)
          .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _productOptions = products;
        _rehydratePrefilledProducts(products);
      });
      await _resolveMissingPrefilledProductLabels();
    } catch (_) {
      if (!mounted) return;
      setState(() => _productOptions = const <_ProductOption>[]);
    } finally {
      if (mounted) {
        setState(() => _loadingProducts = false);
      }
    }
  }

  void _rehydratePrefilledProducts(List<_ProductOption> products) {
    for (final rowIndex in _rowOrder) {
      final selected = _productForRow(rowIndex);
      if (selected == null) continue;
      final match = products
          .where((p) => p.id == selected.id)
          .cast<_ProductOption?>()
          .firstWhere((p) => p != null, orElse: () => null);
      if (match != null) {
        _setSelectedProductForRow(rowIndex, match);
        if (_descriptionControllerForRow(rowIndex).text.trim().isEmpty &&
            match.description.trim().isNotEmpty) {
          _descriptionControllerForRow(rowIndex).text = match.description;
        }
      }
    }
  }

  bool _looksLikeUuid(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return false;
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidPattern.hasMatch(raw);
  }

  Future<void> _resolveMissingPrefilledProductLabels() async {
    final targets = <int, _ProductOption>{};
    for (final rowIndex in _rowOrder) {
      final selected = _productForRow(rowIndex);
      if (selected == null) continue;
      final name = selected.name.trim();
      if (name.isEmpty || name == selected.id || _looksLikeUuid(name)) {
        targets[rowIndex] = selected;
      }
    }
    if (targets.isEmpty) return;

    var changed = false;
    for (final entry in targets.entries) {
      final rowIndex = entry.key;
      final selected = entry.value;
      final matches = await _searchProducts(selected.id);
      if (!mounted) return;
      final exact = matches
          .where((p) => p.id == selected.id)
          .cast<_ProductOption?>()
          .firstWhere((p) => p != null, orElse: () => null);
      if (exact != null && exact.name.trim().isNotEmpty) {
        _setSelectedProductForRow(rowIndex, exact);
        if (_descriptionControllerForRow(rowIndex).text.trim().isEmpty &&
            exact.description.trim().isNotEmpty) {
          _descriptionControllerForRow(rowIndex).text = exact.description;
        }
        changed = true;
      }
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  Future<void> _loadQuantityAvailable() async {
    for (final rowIndex in _rowOrder) {
      if (_productForRow(rowIndex) != null) {
        await _loadQuantityAvailableForRow(rowIndex);
      }
    }
  }

  bool _hasAnyItemInTable() => _rowOrder.any((i) => _productForRow(i) != null);

  Future<void> _onWarehouseChanged(Warehouse? value) async {
    if (value == null) return;
    if (_selectedWarehouse != null && _hasAnyItemInTable()) {
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WarehouseChangeConfirmDialog(warehouseName: value.name),
      );
      if (proceed != true) return;
    }
    setState(() => _selectedWarehouse = value);
    await _loadQuantityAvailable();
  }

  _ProductOption? _productForRow(int rowIndex) {
    if (rowIndex == 0) return _selectedProduct;
    if (rowIndex == 1) return _secondarySelectedProduct;
    return _extraSelectedProducts[rowIndex];
  }

  TextEditingController _descriptionControllerForRow(int rowIndex) {
    if (rowIndex == 0) return _itemDescriptionController;
    if (rowIndex == 1) return _secondaryItemDescriptionController;
    return _extraDescriptionControllers.putIfAbsent(
      rowIndex,
      () => TextEditingController(),
    );
  }

  TextEditingController _adjustedControllerForRow(int rowIndex) {
    if (rowIndex == 0) return _adjustedController;
    if (rowIndex == 1) return _secondaryAdjustedController;
    return _extraAdjustedControllers.putIfAbsent(
      rowIndex,
      () => TextEditingController(),
    );
  }

  TextEditingController _newOnHandControllerForRow(int rowIndex) {
    final map = _extraNewOnHandControllers ??= <int, TextEditingController>{};
    return map.putIfAbsent(rowIndex, () => TextEditingController());
  }

  double _quantityAvailableForRow(int rowIndex) {
    if (rowIndex == 0) return _quantityAvailable;
    if (rowIndex == 1) return _secondaryQuantityAvailable;
    return _extraQuantitiesAvailable[rowIndex] ?? 0;
  }

  double _currentValueForRow(int rowIndex) {
    final explicitBaseline = _currentValueBaselineForRow(rowIndex);
    if (explicitBaseline != null && explicitBaseline >= 0) {
      return explicitBaseline;
    }

    final qty = _quantityAvailableForRow(rowIndex);
    if (qty <= 0) return 0;
    // Fallback only: use resolved row cost if backend value baseline is unavailable.
    final cost = _effectiveCostPriceForRow(rowIndex);
    return qty * cost;
  }

  double _adjustedValueForRow(int rowIndex) {
    return double.tryParse(_adjustedControllerForRow(rowIndex).text) ?? 0;
  }

  double _newQuantityForRow(int rowIndex) {
    return _quantityAvailableForRow(rowIndex) + _adjustedValueForRow(rowIndex);
  }

  String _formatSignedQtyInput(double value) {
    if (value == value.roundToDouble()) {
      final txt = value.toStringAsFixed(0);
      return value > 0 ? '+$txt' : txt;
    }
    final txt = value.toStringAsFixed(2);
    return value > 0 ? '+$txt' : txt;
  }

  String _formatQtyInput(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  String _normalizeNumericInputText(String raw, {bool allowSign = false}) {
    var text = raw.trim();
    if (text.isEmpty) return '';

    var sign = '';
    if (allowSign && (text.startsWith('+') || text.startsWith('-'))) {
      sign = text[0];
      text = text.substring(1);
    }

    final parsed = double.tryParse(text);
    if (parsed == null) return raw;
    final normalized = _formatQtyInput(parsed);
    if (!allowSign) return normalized;
    if (normalized == '0') return '0';
    return sign.isNotEmpty ? '$sign$normalized' : normalized;
  }

  void _syncAdjustedFromNewOnHand(int rowIndex, String text) {
    if (text.trim().isEmpty) {
      _adjustedControllerForRow(rowIndex).clear();
      return;
    }
    final target = double.tryParse(text.trim());
    if (target == null) return;
    final available = _quantityAvailableForRow(rowIndex);
    _adjustedControllerForRow(rowIndex).text = _formatSignedQtyInput(
      target - available,
    );
  }

  void _syncNewOnHandFromAdjusted(int rowIndex, String text) {
    if (text.trim().isEmpty) {
      _newOnHandControllerForRow(rowIndex).clear();
      return;
    }
    final adjusted = double.tryParse(text.trim());
    if (adjusted == null) return;
    final available = _quantityAvailableForRow(rowIndex);
    _newOnHandControllerForRow(rowIndex).text = _formatQtyInput(
      available + adjusted,
    );
  }

  double _valueDeltaForRow(int rowIndex) {
    return _adjustedValueForRow(rowIndex) - _currentValueForRow(rowIndex);
  }

  String _activeTagsStringForRow(int rowIndex) {
    final tags = _lineReportingTags[rowIndex];
    if (tags == null || tags.isEmpty) return '';
    return tags.values.where((v) => v != null).join(', ');
  }

  Future<void> _loadQuantityAvailableForRow(int rowIndex) async {
    final product = _productForRow(rowIndex);
    if (product == null) return;
    try {
      final response = await _apiClient.get(
        '/products/${product.id}/warehouse-stocks',
      );
      final dynamic payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic>
                ? (payload['data'] as List<dynamic>? ?? const <dynamic>[])
                : const <dynamic>[]);

      double quantity = 0;
      double? currentValueBaseline;
      if (rows.isNotEmpty) {
        final selectedWarehouseId = _selectedWarehouse?.id;
        Map<String, dynamic>? matched;
        for (final row in rows) {
          if (row is! Map<String, dynamic>) continue;
          if (selectedWarehouseId == null ||
              selectedWarehouseId.isEmpty ||
              row['warehouse_id']?.toString() == selectedWarehouseId) {
            matched = row;
            break;
          }
        }
        final target = matched ?? rows.first;
        if (target is Map<String, dynamic>) {
          double? toDouble(dynamic value) {
            if (value is num) return value.toDouble();
            return double.tryParse((value ?? '').toString());
          }

          quantity =
              (target['current_stock'] as num?)?.toDouble() ??
              (target['quantity_on_hand'] as num?)?.toDouble() ??
              0;

          currentValueBaseline =
              toDouble(target['current_value']) ??
              toDouble(target['current_stock_value']) ??
              toDouble(target['inventory_value']) ??
              toDouble(target['stock_value']) ??
              toDouble(target['total_value']);

          if (currentValueBaseline == null) {
            final avgCost =
                toDouble(target['avg_cost']) ??
                toDouble(target['average_cost']) ??
                toDouble(target['weighted_avg_cost']) ??
                toDouble(target['weighted_average_cost']) ??
                toDouble(target['cost_price']) ??
                toDouble(target['purchase_rate']);
            if (avgCost != null) {
              currentValueBaseline = quantity * avgCost;
            }
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _setQuantityAvailableForRow(rowIndex, quantity);
        _setCurrentValueBaselineForRow(rowIndex, currentValueBaseline);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setQuantityAvailableForRow(rowIndex, 0);
        _setCurrentValueBaselineForRow(rowIndex, null);
      });
    }
  }

  void _setSelectedProductForRow(int rowIndex, _ProductOption? value) {
    if (rowIndex == 0) {
      _selectedProduct = value;
    } else if (rowIndex == 1) {
      _secondarySelectedProduct = value;
    } else {
      _extraSelectedProducts[rowIndex] = value;
    }
  }

  void _setQuantityAvailableForRow(int rowIndex, double value) {
    if (rowIndex == 0) {
      _quantityAvailable = value;
    } else if (rowIndex == 1) {
      _secondaryQuantityAvailable = value;
    } else {
      _extraQuantitiesAvailable[rowIndex] = value;
    }
    _syncNewOnHandFromAdjusted(
      rowIndex,
      _adjustedControllerForRow(rowIndex).text,
    );
  }

  double? _currentValueBaselineForRow(int rowIndex) {
    if (rowIndex == 0) return _currentValueBaseline;
    if (rowIndex == 1) return _secondaryCurrentValueBaseline;
    return _extraCurrentValueBaselines[rowIndex];
  }

  void _setCurrentValueBaselineForRow(int rowIndex, double? value) {
    if (rowIndex == 0) {
      _currentValueBaseline = value;
    } else if (rowIndex == 1) {
      _secondaryCurrentValueBaseline = value;
    } else {
      _extraCurrentValueBaselines[rowIndex] = value;
    }
  }

  void _ensureRowInfrastructure(int rowIndex) {
    while (_selectedLineItems.length <= rowIndex) {
      _selectedLineItems.add(false);
    }
    while (_reportingTagLayerLinks.length <= rowIndex) {
      _reportingTagLayerLinks.add(LayerLink());
    }
    while (_rowActionsLayerLinks.length <= rowIndex) {
      _rowActionsLayerLinks.add(LayerLink());
    }
    while (_costPriceLayerLinks.length <= rowIndex) {
      _costPriceLayerLinks.add(LayerLink());
    }
    _lineReportingTags.putIfAbsent(rowIndex, () => <String, String?>{});
    _descriptionControllerForRow(rowIndex);
    _adjustedControllerForRow(rowIndex);
  }

  void _handleDateFocusChange() {
    if (!_dateFocusNode.hasFocus) {
      _syncDateFromInput(showToastOnError: false, normalizeText: true);
    }
  }

  DateTime? _parseDateInput(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;
    final normalized = cleaned.replaceAll('-', '/');
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(normalized);
    } catch (_) {
      return null;
    }
  }

  bool _syncDateFromInput({
    required bool showToastOnError,
    required bool normalizeText,
  }) {
    final raw = _dateController.text.trim();
    final parsed = _parseDateInput(raw);
    if (parsed == null) {
      if (showToastOnError) {
        _toast('Please enter a valid date in DD/MM/YYYY format.');
      }
      return false;
    }

    _adjustmentDate = parsed;
    if (normalizeText) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(parsed);
    }
    return true;
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final returnTo = (widget.returnToPath ?? '').trim();
    if (returnTo.isNotEmpty) {
      context.go(returnTo);
      return;
    }
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
    context.go('/$orgId/inventory/adjustments');
  }

  Future<void> _submit(String status) async {
    final user = ref.read(authUserProvider);
    final entity = ref.read(entityProvider);
    final normalizedTargetStatus = normalizeTransactionStatus(status);
    final decision = TransactionStatusTransitionGuard.canTransition(
      user: user,
      transactionType: 'inventory.adjustment',
      fromStatus: _currentStatus,
      toStatus: normalizedTargetStatus,
      branchId: entity.branchId,
      warehouseId: _selectedWarehouse?.id,
      requiredPermission: 'inventory.adjustment.edit',
      reason: _selectedReason,
    );
    if (!decision.allowed) {
      _toast(decision.reason);
      return;
    }

    if (!_syncDateFromInput(showToastOnError: true, normalizeText: true)) {
      return;
    }
    if (_selectedAccountId == null || _selectedAccountId!.trim().isEmpty) {
      _toast('Please select account.');
      return;
    }
    if (_selectedReason == null || _selectedReason!.trim().isEmpty) {
      _toast('Please select reason.');
      return;
    }
    if (_selectedWarehouse == null) {
      _toast('Please select a warehouse.');
      return;
    }

    final populatedRows = _rowOrder
        .where(
          (rowIndex) =>
              _productForRow(rowIndex) != null &&
              _adjustedControllerForRow(rowIndex).text.trim().isNotEmpty,
        )
        .toList(growable: false);

    if (populatedRows.isEmpty) {
      _toast('Please select an item in table.');
      return;
    }

    // Construct multi-line payload for debugging/future backend
    final List<Map<String, dynamic>> items = populatedRows.map((idx) {
      final product = _productForRow(idx)!;
      final rawInput = _adjustedValueForRow(idx);
      final costPrice = _lineCostPrices[idx] ?? product.costPrice ?? 0.0;
      final tags = _lineReportingTags[idx] ?? {};
      // In value mode rawInput = absolute new value; delta = newValue - currentValue
      final valueDelta = _mode == 'value' ? _valueDeltaForRow(idx) : 0.0;
      final qtyAdjusted = _mode == 'quantity' ? rawInput : 0.0;

      return {
        'product_id': product.id,
        'quantity_before': _quantityAvailableForRow(idx),
        'quantity_adjusted': qtyAdjusted,
        'quantity_after': _mode == 'quantity'
            ? _newQuantityForRow(idx)
            : _quantityAvailableForRow(idx),
        'cost_price': costPrice,
        'adjustment_value': _mode == 'value'
            ? valueDelta
            : (qtyAdjusted * costPrice),
        'reporting_tags': tags,
        'batch_details': _rowBatchResults[idx]?.batches
            .map(
              (b) => {
                'batch_id': b.batchId,
                'reference': b.batchReference,
                'quantity': b.quantity,
                'mfd_month_year': b.mfdDate != null
                    ? DateFormat('MM/yyyy').format(b.mfdDate!)
                    : null,
                'expiry_month_year': b.expiryDate != null
                    ? DateFormat('MM/yyyy').format(b.expiryDate!)
                    : null,
              },
            )
            .toList(),
      };
    }).toList();

    print('STRUCTURED ADJUSTMENT PAYLOAD:');
    print(
      const JsonEncoder.withIndent('  ').convert({
        'warehouse_id': _selectedWarehouse!.id,
        'adjustment_date': _adjustmentDate.toIso8601String(),
        'reason': _selectedReason,
        'status': status,
        'adjustment_type': _mode,
        'items': items,
      }),
    );

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final lineItems = <InventoryAdjustmentItem>[];
      var totalQuantityBefore = 0.0;
      var totalQuantityAdjusted = 0.0;
      var totalQuantityAfter = 0.0;
      var totalAdjustmentValue = 0.0;

      for (final rowIndex in populatedRows) {
        final rowProduct = _productForRow(rowIndex)!;
        final rawAdjustedValue = _adjustedValueForRow(rowIndex);
        final rowQuantityBefore = _quantityAvailableForRow(rowIndex);
        final rowQuantityAdjusted = _mode == 'quantity'
            ? rawAdjustedValue
            : 0.0;
        final rowQuantityAfter = _mode == 'quantity'
            ? _newQuantityForRow(rowIndex)
            : rowQuantityBefore;
        final rowCostPrice =
            _lineCostPrices[rowIndex] ?? rowProduct.costPrice ?? 0.0;
        final rowAdjustmentValue = _mode == 'value'
            ? _valueDeltaForRow(rowIndex)
            : rowQuantityAdjusted * rowCostPrice;

        final rowBatches =
            _rowBatchResults[rowIndex]?.batches ?? const <_AdjBatch>[];
        final itemBatchAllocations = rowBatches
            .map(
              (b) => InventoryAdjustmentBatchAllocation(
                batchId: b.batchId.trim().isEmpty ? null : b.batchId.trim(),
                batchReference: b.batchReference.trim().isEmpty
                    ? null
                    : b.batchReference.trim(),
                quantityIn: b.quantity,
                quantityOut: 0,
                binId: b.binId,
              ),
            )
            .toList(growable: false);
        final firstBatch = rowBatches.isNotEmpty ? rowBatches.first : null;

        lineItems.add(
          InventoryAdjustmentItem(
            id: '',
            productId: rowProduct.id,
            quantityAdjusted: rowQuantityAdjusted,
            costPrice: rowCostPrice,
            batchId: firstBatch != null && firstBatch.batchId.trim().isNotEmpty
                ? firstBatch.batchId.trim()
                : null,
            batchReference:
                firstBatch != null &&
                    firstBatch.batchReference.trim().isNotEmpty
                ? firstBatch.batchReference.trim()
                : null,
            batchAllocations: itemBatchAllocations,
          ),
        );

        totalQuantityBefore += rowQuantityBefore;
        totalQuantityAdjusted += rowQuantityAdjusted;
        totalQuantityAfter += rowQuantityAfter;
        totalAdjustmentValue += rowAdjustmentValue;
      }

      final anchorRowIndex = populatedRows.first;
      final anchorProduct = _productForRow(anchorRowIndex)!;
      final anchorCostPrice =
          _lineCostPrices[anchorRowIndex] ?? anchorProduct.costPrice ?? 0.0;

      final adjustment = InventoryAdjustment(
        id: _editingSourceId ?? '',
        productId: anchorProduct.id,
        productCode: anchorProduct.code,
        productName: anchorProduct.name,
        warehouseId: _selectedWarehouse!.id,
        warehouseName: _selectedWarehouse!.name,
        adjustmentDate: _adjustmentDate,
        adjustmentType: _mode,
        reason: _selectedReason ?? '',
        quantityBefore: totalQuantityBefore,
        quantityAdjusted: totalQuantityAdjusted,
        quantityAfter: totalQuantityAfter,
        costPrice: anchorCostPrice,
        adjustmentValue: totalAdjustmentValue,
        accountId: _selectedAccountId,
        referenceNumber: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        notes: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        adjustedBy: null,
        status: normalizedTargetStatus,
        createdAt: now,
        updatedAt: now,
        items: lineItems,
      );

      final repo = ref.read(adjustmentsRepositoryProvider);
      if (_editingSourceId != null && !widget.isClone) {
        await repo.updateAdjustment(_editingSourceId!, adjustment);
        ref.invalidate(inventoryAdjustmentsListProvider);
      } else {
        await ref.read(inventoryAdjustmentsActionsProvider).create(adjustment);
      }
      if (user != null) {
        final auditEvent = TransactionStatusTransitionGuard.buildAuditEvent(
          transactionType: 'inventory.adjustment',
          transactionId: _editingSourceId ?? adjustment.id,
          beforeStatus: _currentStatus,
          afterStatus: normalizedTargetStatus,
          actor: user,
          reason: _selectedReason ?? 'Status transition',
          permissionUsed: decision.requiredPermission,
          branchId: entity.branchId,
          warehouseId: _selectedWarehouse?.id,
          metadata: <String, dynamic>{
            'entity_context': entity.entityId,
            'branch_context': entity.branchId,
            'warehouse_context': _selectedWarehouse?.id,
            'mode': _mode,
          },
        );
        AppLogger.info(
          'Inventory adjustment status transition',
          module: 'inventory_adjustments',
          userId: user.id,
          orgId: user.orgId,
          data: auditEvent.toJson(),
        );
      }
      _currentStatus = normalizedTargetStatus;
      if (!mounted) return;
      final successMsg = status == 'draft'
          ? 'Draft saved.'
          : status == 'submitted'
          ? 'Adjustment submitted successfully.'
          : 'Adjustment approved and saved.';
      _toast(successMsg, success: true);
      _goBack();
    } catch (error) {
      _toast(error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _toast(String message, {bool success = false}) {
    if (success) {
      ZerpaiToast.success(context, message);
      return;
    }
    ZerpaiToast.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(warehousesProvider);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: const ItemDetailsSidebar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const Divider(height: 1, color: AppTheme.borderColor),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildModeRow(),
                            _buildFormRow(
                              label: 'Reference Number',
                              child: _field(
                                CustomTextField(
                                  controller: _referenceController,
                                  forceUppercase: false,
                                  contentCase: ContentCase.none,
                                  hintText: '',
                                ),
                              ),
                            ),
                            _buildFormRow(
                              label: 'Date',
                              required: true,
                              child: _field(
                                CustomTextField(
                                  key: _dateFieldKey,
                                  controller: _dateController,
                                  focusNode: _dateFocusNode,
                                  keyboardType: TextInputType.datetime,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9/-]'),
                                    ),
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  onChanged: (value) {
                                    final parsed = _parseDateInput(value);
                                    if (parsed != null) {
                                      _adjustmentDate = parsed;
                                    }
                                  },
                                  onSubmitted: (_) {
                                    _syncDateFromInput(
                                      showToastOnError: false,
                                      normalizeText: true,
                                    );
                                  },
                                  hintText: 'DD/MM/YYYY',
                                  suffixWidget: IconButton(
                                    onPressed: () async {
                                      final picked =
                                          await ZerpaiDatePicker.show(
                                            context,
                                            initialDate: _adjustmentDate,
                                            targetKey: _dateFieldKey,
                                          );
                                      if (picked == null) return;
                                      setState(() {
                                        _adjustmentDate = picked;
                                        _dateController.text = DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(picked);
                                      });
                                    },
                                    icon: const Icon(
                                      LucideIcons.calendar,
                                      size: 15,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _buildFormRow(
                              label: 'Account',
                              required: true,
                              child: _field(
                                _loadingAccounts
                                    ? const Skeleton(
                                        height: 38,
                                        width: double.infinity,
                                        borderRadius: 4,
                                      )
                                    : AccountTreeDropdown(
                                        value: _selectedAccountId,
                                        nodes: _accountNodes,
                                        onSearch: _searchAccounts,
                                        hint: 'Select account',
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedAccountId = value;
                                          });
                                        },
                                        height: 38,
                                      ),
                              ),
                            ),
                            _buildFormRow(
                              label: 'Reason',
                              required: true,
                              child: _field(
                                _loadingReasons
                                    ? const SizedBox(
                                        width: double.infinity,
                                        child: Skeleton(
                                          height: 38,
                                          width: double.infinity,
                                          borderRadius: 4,
                                        ),
                                      )
                                    : FormDropdown<String>(
                                        value: _selectedReason,
                                        items: _reasonOptionLabels,
                                        hint: 'Select a reason',
                                        onChanged: (value) {
                                          setState(
                                            () => _selectedReason = value,
                                          );
                                        },
                                        menuWidth: _fieldWidth,
                                        itemEstimatedHeight: 36,
                                        menuMaxHeight: 320,
                                        showSettings: true,
                                        settingsLabel: 'Manage Reasons',
                                        settingsIcon: LucideIcons.settings,
                                        onSettingsTap: _showManageReasonsDialog,
                                        forceUppercase: false,
                                      ),
                              ),
                            ),
                            _buildFormRow(
                              label: 'Warehouse',
                              required: true,
                              child: _field(
                                warehousesAsync.when(
                                  data: (warehouses) => FormDropdown<Warehouse>(
                                    value: _selectedWarehouse,
                                    items: warehouses,
                                    hint: 'Select a warehouse',
                                    onChanged: _onWarehouseChanged,
                                    displayStringForValue: (w) => w.name,
                                    searchStringForValue: (w) =>
                                        '${w.name} ${w.code ?? ''}',
                                  ),
                                  loading: () => const SizedBox(
                                    width: double.infinity,
                                    child: Skeleton(
                                      height: 38,
                                      width: double.infinity,
                                      borderRadius: 4,
                                    ),
                                  ),
                                  error: (_, __) => const Text(
                                    'Unable to load warehouses',
                                    style: TextStyle(color: AppTheme.errorRed),
                                  ),
                                ),
                              ),
                            ),
                            _buildFormRow(
                              label: 'Description',
                              child: _field(
                                CustomTextField(
                                  controller: _descriptionController,
                                  maxLines: 3,
                                  hintText: 'Max. 500 characters',
                                  forceUppercase: false,
                                  contentCase: ContentCase.sentence,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            IgnorePointer(
                              ignoring: _selectedWarehouse == null,
                              child: Opacity(
                                opacity: _selectedWarehouse == null
                                    ? 0.38
                                    : 1.0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildItemTableCard(),
                                    const SizedBox(height: 18),
                                    _buildAttachmentSection(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = widget.isClone
        ? 'Clone Adjustment'
        : (_editingSourceId != null ? 'Edit Adjustment' : 'New Adjustment');
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: _goBack,
            icon: const Icon(
              LucideIcons.x,
              size: 22,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeRow() {
    return _buildFormRow(
      label: 'Mode of adjustment',
      child: RadioGroup<String>(
        groupValue: _mode,
        onChanged: (value) {
          if (value == null) return;
          setState(() => _mode = value);
        },
        child: SizedBox(
          width: _fieldWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modeOption(label: 'Quantity Adjustment', value: 'quantity'),
              _modeOption(label: 'Value Adjustment', value: 'value'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeOption({required String label, required String value}) {
    return InkWell(
      onTap: () => setState(() => _mode = value),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              activeColor: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTableCard() {
    final bool quantityMode = _mode == 'quantity';
    final String headerB = quantityMode
        ? 'QUANTITY AVAILABLE'
        : 'CURRENT VALUE';
    final String headerC = quantityMode
        ? 'NEW QUANTITY ON HAND'
        : 'CHANGED VALUE';
    final String headerD = quantityMode
        ? 'QUANTITY ADJUSTED'
        : 'ADJUSTED VALUE';

    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _tableWidth + 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _tableWidth,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      _buildTableTopBar(),
                      if (_bulkSelectionMode && _hasSelectedLineItems)
                        _buildBulkReportingStrip(),
                      _buildTableColumnHeader(headerB, headerC, headerD),
                      _buildRowBlocksList(quantityMode: quantityMode),
                    ],
                  ),
                ),
                _buildOutsideRowActionsHoverZones(),
                _buildOutsideRowActionsOverlay(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _tableActionBtn(
                icon: Icons.add_circle_outline,
                label: 'Add New Row',
                onTap: () {
                  _insertNewRow(
                    afterRowIndex: _rowOrder.isEmpty ? null : _rowOrder.last,
                  );
                },
              ),
              const SizedBox(width: 12),
              _tableActionBtn(
                icon: Icons.add_circle_outline,
                label: 'Add Items in Bulk',
                onTap: () {
                  _openBulkItemsDialog();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableTopBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFFF6F7FB),
      child: Row(
        children: [
          const Text(
            'Item Table',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          CompositedTransformTarget(
            link: _bulkActionsLayerLink,
            child: InkWell(
              onTap: _toggleBulkActionsMenu,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Bulk Actions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkReportingStrip() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _showBulkUpdateLineItemsDialog,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Update Reporting Tags',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _clearSelectedLineItems,
            icon: Icon(LucideIcons.x, size: 18, color: accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTableColumnHeader(String b, String c, String d) {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          if (_bulkSelectionMode) const SizedBox(width: 24),
          const Expanded(
            flex: 52,
            child: Padding(
              padding: EdgeInsets.only(left: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TableHeader('ITEM DETAILS', align: TextAlign.start),
              ),
            ),
          ),
          _headerDivider(),
          Expanded(
            flex: 20,
            child: Align(alignment: Alignment.center, child: _TableHeader(b)),
          ),
          _headerDivider(),
          Expanded(
            flex: 18,
            child: Align(alignment: Alignment.center, child: _TableHeader(c)),
          ),
          _headerDivider(),
          Expanded(
            flex: 16,
            child: Align(alignment: Alignment.center, child: _TableHeader(d)),
          ),
        ],
      ),
    );
  }

  Widget _buildRowBlocksList({required bool quantityMode}) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _rowOrder.length,
      proxyDecorator: (child, index, animation) {
        return Material(color: Colors.transparent, child: child);
      },
      onReorder: _reorderRows,
      itemBuilder: (context, index) {
        final rowIndex = _rowOrder[index];
        return Container(
          key: ValueKey('adjustment-row-$rowIndex'),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTableDataRow(
                quantityMode: quantityMode,
                rowIndex: rowIndex,
                dragIndex: index,
              ),
              if (_showAllAdditionalInformation)
                _buildReportingTagRow(
                  rowIndex: rowIndex,
                  showCostPrice:
                      _productForRow(rowIndex) != null && _mode == 'quantity',
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableDataRow({
    required bool quantityMode,
    required int rowIndex,
    required int dragIndex,
  }) {
    final bool hasSelection = _productForRow(rowIndex) != null;
    final rowHeight = hasSelection ? 84.0 : 56.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItemRowIndex = rowIndex),
      onExit: (_) {
        if (_openRowActionsRowIndex == null &&
            _hoveredItemRowIndex == rowIndex) {
          setState(() => _hoveredItemRowIndex = null);
        }
      },
      child: SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            if (_bulkSelectionMode)
              SizedBox(
                width: 24,
                child: Align(
                  alignment: hasSelection || rowIndex != _rowOrder.first
                      ? Alignment.topCenter
                      : Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(top: hasSelection ? 10 : 14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: Checkbox(
                        value: _selectedLineItems[rowIndex],
                        onChanged: (value) {
                          setState(() {
                            _selectedLineItems[rowIndex] = value ?? false;
                            if (!_hasSelectedLineItems) {
                              _bulkSelectionMode = false;
                            }
                          });
                        },
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        activeColor: AppTheme.primaryBlue,
                        side: const BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              flex: 52,
              child: _buildItemDetailsCell(
                rowIndex: rowIndex,
                dragIndex: dragIndex,
              ),
            ),
            _headerDivider(),
            Expanded(
              flex: 20,
              child: _buildMetricCell(
                quantityMode: quantityMode,
                rowIndex: rowIndex,
                type: _MetricCellType.first,
              ),
            ),
            _headerDivider(),
            Expanded(
              flex: 18,
              child: _buildMetricCell(
                quantityMode: quantityMode,
                rowIndex: rowIndex,
                type: _MetricCellType.second,
              ),
            ),
            _headerDivider(),
            Expanded(
              flex: 16,
              child: _buildAdjustedCell(
                quantityMode: quantityMode,
                rowIndex: rowIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetailsCell({
    required int rowIndex,
    required int dragIndex,
  }) {
    final selectedProduct = _productForRow(rowIndex);
    final descriptionController = _descriptionControllerForRow(rowIndex);
    final bool hasSelection = selectedProduct != null;
    final bool showSelectedRowActions =
        hasSelection &&
        (_hoveredItemRowIndex == rowIndex ||
            _openRowActionsRowIndex == rowIndex);
    final bool showNameSkeleton =
        hasSelection && _needsProductLabelHydration(selectedProduct);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 7, 10, 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: ReorderableDragStartListener(
                index: dragIndex,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(
                    child: Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: AppTheme.borderColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(
              LucideIcons.image,
              size: 15,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: hasSelection
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: showNameSkeleton
                                ? const Skeleton(height: 14, width: 220)
                                : InkWell(
                                    onTap: () =>
                                        _openItemDetailsDrawerForRow(rowIndex),
                                    child: Text(
                                      selectedProduct.name.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 38,
                            child: IgnorePointer(
                              ignoring: !showSelectedRowActions,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 120),
                                opacity: showSelectedRowActions ? 1 : 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CompositedTransformTarget(
                                      link: _rowActionsLayerLinks[rowIndex],
                                      child: InkWell(
                                        onTap: () =>
                                            _toggleRowActionsMenu(rowIndex),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppTheme.textSecondary
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                          child: const Icon(
                                            LucideIcons.moreHorizontal,
                                            size: 10,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => _clearRowSelection(rowIndex),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.textSecondary
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.x,
                                          size: 10,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8FA),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: TextField(
                          controller: descriptionController,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Add a description to your item',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : FormDropdown<_ProductOption>(
                    value: selectedProduct,
                    items: _productOptions ?? const <_ProductOption>[],
                    hint: 'Type or click to select an item.',
                    isLoading: _loadingProducts,
                    onSearch: _searchProducts,
                    onChanged: (value) async {
                      setState(() {
                        _setSelectedProductForRow(rowIndex, value);
                        _setCurrentValueBaselineForRow(rowIndex, null);
                        descriptionController.text = value?.description ?? '';
                        _lineCostPrices[rowIndex] =
                            value?.costPrice ?? value?.recentPrice;
                        if (value != null) {
                          _ensureTrailingBlankRowInState();
                        }
                      });
                      await _loadQuantityAvailableForRow(rowIndex);
                    },
                    displayStringForValue: (item) =>
                        '${item.name} (${item.code})',
                    searchStringForValue: (item) => '${item.name} ${item.code}',
                    forceUppercase: false,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCell({
    required bool quantityMode,
    required int rowIndex,
    required _MetricCellType type,
  }) {
    final bool hasSelection = _productForRow(rowIndex) != null;
    String text = '';
    Widget? extra;
    TextStyle style = const TextStyle(
      fontSize: 13,
      color: AppTheme.textSecondary,
    );

    if (type == _MetricCellType.first) {
      if (quantityMode) {
        text = hasSelection
            ? _quantityAvailableForRow(rowIndex).toStringAsFixed(2)
            : '';
        if (hasSelection) {
          style = const TextStyle(
            fontSize: 13,
            color: Colors.black,
            fontWeight: FontWeight.w700,
          );
          extra = const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'pcs',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
      } else {
        text = hasSelection
            ? '\u20B9${_currentValueForRow(rowIndex).toStringAsFixed(2)}'
            : '';
        style = const TextStyle(
          fontSize: 13,
          color: Colors.black,
          fontWeight: FontWeight.w700,
        );
        if (hasSelection) {
          extra = const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: AppTheme.primaryBlueDark,
            ),
          );
        }
      }
    } else {
      if (quantityMode) {
        if (!hasSelection) {
          return Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
          );
        }
        final controller = _newOnHandControllerForRow(rowIndex);
        if (controller.text.trim().isEmpty) {
          controller.text = _formatQtyInput(_newQuantityForRow(rowIndex));
        }
        final adjusted = _adjustedValueForRow(rowIndex);
        final needsBatchWarning =
            _mode == 'quantity' &&
            hasSelection &&
            (_productForRow(rowIndex)?.trackBatches ?? false) &&
            adjusted < 0;
        return Container(
          padding: const EdgeInsets.only(top: 8, right: 10),
          alignment: Alignment.topRight,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (needsBatchWarning) ...[
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AppTheme.primaryBlueDark,
                ),
                const SizedBox(width: 4),
              ],
              SizedBox(
                width: 88,
                height: 30,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (val) {
                    final normalized = _normalizeNumericInputText(val);
                    if (normalized != val) {
                      controller.value = TextEditingValue(
                        text: normalized,
                        selection: TextSelection.collapsed(
                          offset: normalized.length,
                        ),
                      );
                    }
                    _syncAdjustedFromNewOnHand(rowIndex, val);
                    setState(() {});
                  },
                  onEditingComplete: () {
                    final normalized = _normalizeNumericInputText(
                      controller.text,
                    );
                    controller.value = TextEditingValue(
                      text: normalized,
                      selection: TextSelection.collapsed(
                        offset: normalized.length,
                      ),
                    );
                    _syncAdjustedFromNewOnHand(rowIndex, normalized);
                    setState(() {});
                  },
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6A7298),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Value mode: second column = editable Changed Value input
        if (!hasSelection) {
          return Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
          );
        }
        final controller = _adjustedControllerForRow(rowIndex);
        return Container(
          padding: const EdgeInsets.only(right: 10),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: SizedBox(
            height: 30,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (_) => setState(() {}),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                prefixText: '\u20B9',
                prefixStyle: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                hintText: '0.00',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF6A7298)),
              ),
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
        );
      }
    }

    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(text, style: style),
          if (extra != null) extra,
        ],
      ),
    );
  }

  Widget _buildAdjustedCell({
    required bool quantityMode,
    required int rowIndex,
  }) {
    final product = _productForRow(rowIndex);
    final bool hasSelection = product != null;

    // Value mode: show computed delta (changedValue - currentValue) read-only
    if (!quantityMode) {
      final changedVal =
          double.tryParse(_adjustedControllerForRow(rowIndex).text) ?? 0.0;
      final currentVal = hasSelection ? _currentValueForRow(rowIndex) : 0.0;
      final delta = changedVal - currentVal;
      final deltaText = hasSelection
          ? (delta >= 0
                ? '+₹${delta.toStringAsFixed(2)}'
                : '-₹${delta.abs().toStringAsFixed(2)}')
          : '';
      return Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Text(
          deltaText,
          style: TextStyle(
            fontSize: 13,
            color: hasSelection
                ? (delta >= 0 ? AppTheme.successGreen : AppTheme.errorRed)
                : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    final double? adjustedQty = double.tryParse(
      _adjustedControllerForRow(rowIndex).text,
    );
    final bool hasNonZeroQty = adjustedQty != null && adjustedQty != 0;
    final bool isBatchTracked =
        hasSelection && product.trackBatches && quantityMode && hasNonZeroQty;
    final savedBatchResult = _rowBatchResults[rowIndex];
    final bool hasSavedBatches =
        savedBatchResult != null &&
        savedBatchResult.batches.isNotEmpty &&
        savedBatchResult.totalQuantity > 0;
    final bool isSubtraction = (adjustedQty ?? 0) < 0;
    final bool needsBatchWarning = isBatchTracked && isSubtraction;

    final inputField = SizedBox(
      height: 30,
      child: TextField(
        controller: _adjustedControllerForRow(rowIndex),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[-+0-9.]')),
        ],
        onChanged: (val) {
          final normalized = _normalizeNumericInputText(val, allowSign: true);
          if (normalized != val) {
            _adjustedControllerForRow(rowIndex).value = TextEditingValue(
              text: normalized,
              selection: TextSelection.collapsed(offset: normalized.length),
            );
          }
          _syncNewOnHandFromAdjusted(rowIndex, val);
          setState(() {});
        },
        onEditingComplete: () {
          final controller = _adjustedControllerForRow(rowIndex);
          final normalized = _normalizeNumericInputText(
            controller.text,
            allowSign: true,
          );
          controller.value = TextEditingValue(
            text: normalized,
            selection: TextSelection.collapsed(offset: normalized.length),
          );
          _syncNewOnHandFromAdjusted(rowIndex, normalized);
          setState(() {});
        },
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          prefixText: quantityMode ? null : '\u20B9',
          prefixStyle: const TextStyle(
            fontSize: 13,
            color: AppTheme.textPrimary,
          ),
          hintText: quantityMode ? 'Eg. +10, -10' : 'Eg. 100.00',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF6A7298)),
        ),
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
      ),
    );

    return Container(
      padding: const EdgeInsets.only(top: 6, right: 10),
      alignment: Alignment.topRight,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (needsBatchWarning) ...[
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AppTheme.primaryBlueDark,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: hasSelection
                      ? inputField
                      : Text(
                          quantityMode ? 'Eg. +10, -10' : 'Eg. +100',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6A7298),
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (isBatchTracked) ...[
            if (hasSavedBatches) ...[
              const SizedBox(height: 1),
              SizedBox(
                width: 116,
                child: Text(
                  '${_rowBatchResults[rowIndex]!.totalQuantity.toStringAsFixed(0)} pcs added to ${_rowBatchResults[rowIndex]!.batches.length} ${_rowBatchResults[rowIndex]!.batches.length == 1 ? 'batch' : 'batches'}.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 1),
            GestureDetector(
              onTap: () => _showAddBatchesDialog(rowIndex),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: AppTheme.primaryBlueDark,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    hasSavedBatches
                        ? ''
                        : (isSubtraction ? 'Select Batch' : 'Add Batches'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryBlueDark,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutsideRowActionsOverlay() {
    final int? rowIndex = _openRowActionsRowIndex ?? _hoveredItemRowIndex;
    if (rowIndex == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 6,
      top: _rowActionsTopOffset(rowIndex),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredItemRowIndex = rowIndex),
        onExit: (_) {
          if (_openRowActionsRowIndex == null &&
              _hoveredItemRowIndex == rowIndex) {
            setState(() => _hoveredItemRowIndex = null);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompositedTransformTarget(
              link: _rowActionsLayerLinks[rowIndex],
              child: InkWell(
                onTap: () => _toggleRowActionsMenu(rowIndex),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    LucideIcons.moreVertical,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _deleteRow(rowIndex),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(LucideIcons.x, size: 14, color: AppTheme.errorRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutsideRowActionsHoverZones() {
    return Positioned.fill(
      child: Stack(
        children: _rowOrder
            .map(
              (rowIndex) =>
                  _buildOutsideRowActionsHoverZone(rowIndex: rowIndex),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildOutsideRowActionsHoverZone({required int rowIndex}) {
    return Positioned(
      right: 0,
      top: _rowBlockTopOffset(rowIndex),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredItemRowIndex = rowIndex),
        onExit: (_) {
          if (_openRowActionsRowIndex == null &&
              _hoveredItemRowIndex == rowIndex) {
            setState(() => _hoveredItemRowIndex = null);
          }
        },
        child: SizedBox(width: 64, height: _rowBlockHeight(rowIndex)),
      ),
    );
  }

  double _rowActionsTopOffset(int rowIndex) {
    return _rowBlockTopOffset(rowIndex) + ((_rowDataHeight(rowIndex) - 18) / 2);
  }

  double _rowBlockTopOffset(int rowIndex) {
    double offset = 48 + 34;
    if (_bulkSelectionMode && _hasSelectedLineItems) {
      offset += 60;
    }

    final rowPosition = _rowOrder.indexOf(rowIndex);
    if (rowPosition <= 0) {
      return offset;
    }

    for (var i = 0; i < rowPosition; i++) {
      offset += _rowBlockHeight(_rowOrder[i]);
    }

    return offset;
  }

  double _rowBlockHeight(int rowIndex) {
    return _rowDataHeight(rowIndex) + (_showAllAdditionalInformation ? 32 : 0);
  }

  double _rowDataHeight(int rowIndex) {
    return _productForRow(rowIndex) != null ? 84.0 : 56.0;
  }

  Widget _buildReportingTagRow({
    required int rowIndex,
    required bool showCostPrice,
  }) {
    final costPrice = _effectiveCostPriceForRow(rowIndex);
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItemRowIndex = rowIndex),
      onExit: (_) {
        if (_openRowActionsRowIndex == null &&
            _hoveredItemRowIndex == rowIndex) {
          setState(() => _hoveredItemRowIndex = null);
        }
      },
      child: Container(
        height: 32,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          color: Color(0xFFF6F7FB),
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: [
            CompositedTransformTarget(
              link: _reportingTagLayerLinks[rowIndex],
              child: InkWell(
                onTap: () => _showReportingTagsPopover(rowIndex),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.tag,
                      size: 13,
                      color: AppTheme.borderColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _activeTagsStringForRow(rowIndex).isEmpty
                          ? 'Reporting Tags'
                          : _activeTagsStringForRow(rowIndex),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 14,
                      color: AppTheme.borderColor,
                    ),
                  ],
                ),
              ),
            ),

            if (showCostPrice) ...[
              const SizedBox(width: 18),
              CompositedTransformTarget(
                link: _costPriceLayerLinks[rowIndex],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showCostPricePopover(rowIndex),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.tag,
                        size: 13,
                        color: AppTheme.borderColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cost Price: ${_formatCurrency(costPrice)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Edit',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerDivider() {
    return Container(
      width: 1,
      height: double.infinity,
      color: AppTheme.borderColor,
    );
  }

  Widget _tableActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasSelectedLineItems =>
      _rowOrder.any((rowIndex) => _selectedLineItems[rowIndex]);

  double _effectiveCostPriceForRow(int rowIndex) {
    final stored = _lineCostPrices[rowIndex];
    if (stored != null) return stored;
    final product = _productForRow(rowIndex);
    if (product != null) {
      return product.costPrice ?? product.recentPrice ?? 0;
    }
    return 0;
  }

  String _formatCurrency(double value) {
    if (value == value.roundToDouble()) {
      return '\u20B9${value.toStringAsFixed(0)}';
    }
    return '\u20B9${value.toStringAsFixed(2)}';
  }

  void _activateBulkSelectionMode({bool selectAll = false}) {
    setState(() {
      _bulkSelectionMode = true;
      if (selectAll) {
        for (final rowIndex in _rowOrder) {
          _selectedLineItems[rowIndex] = true;
        }
      }
    });
  }

  void _clearSelectedLineItems() {
    setState(() {
      _bulkSelectionMode = false;
      for (final rowIndex in _rowOrder) {
        _selectedLineItems[rowIndex] = false;
      }
    });
  }

  void _toggleBulkActionsMenu() {
    if (_bulkActionsOverlay != null) {
      _hideBulkActionsMenu();
      return;
    }
    _showBulkActionsMenu();
  }

  void _hideBulkActionsMenu() {
    _bulkActionsOverlay?.remove();
    _bulkActionsOverlay = null;
    _hoveredBulkAction = null;
  }

  void _toggleRowActionsMenu(int rowIndex) {
    if (_openRowActionsRowIndex == rowIndex && _rowActionsOverlay != null) {
      _hideRowActionsMenu();
      return;
    }
    _showRowActionsMenu(rowIndex);
  }

  void _hideRowActionsMenu() {
    _rowActionsOverlay?.remove();
    _rowActionsOverlay = null;
    _hoveredRowAction = null;
    _openRowActionsRowIndex = null;
  }

  Future<void> _showAddBatchesDialog(int rowIndex) async {
    final product = _productForRow(rowIndex);
    if (product == null) return;
    final adjustedVal =
        double.tryParse(_adjustedControllerForRow(rowIndex).text) ?? 0;
    final isOutAdjustment = adjustedVal < 0;
    final totalQty = adjustedVal.abs() > 0 ? adjustedVal.abs() : 1.0;

    final result = await showDialog<_AdjBatchDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _AdjAddBatchesDialog(
        productName: product.name,
        warehouseId: _selectedWarehouse?.id ?? '',
        warehouseName: _selectedWarehouse?.name ?? '',
        totalQuantity: totalQty,
        isOutAdjustment: isOutAdjustment,
        savedBatches: _rowBatchResults[rowIndex]?.batches,
        itemId: product.id,
        onFetchBatchSuggestions: (productId, query) => ref
            .read(adjustmentsRepositoryProvider)
            .getBatchSuggestions(productId: productId, query: query),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _rowBatchResults[rowIndex] = result;
        if (result.overwriteLineItem) {
          final signedQty = isOutAdjustment
              ? -result.totalQuantity.abs()
              : result.totalQuantity.abs();
          _adjustedControllerForRow(rowIndex).text = signedQty
              .toString()
              .replaceAll(RegExp(r'\.0$'), '');
          _syncNewOnHandFromAdjusted(
            rowIndex,
            _adjustedControllerForRow(rowIndex).text,
          );
          // State is updated via text controller listener or implicit rebuild
        }
      });
    }
  }

  void _clearRowSelection(int rowIndex) {
    setState(() {
      _setSelectedProductForRow(rowIndex, null);
      _setQuantityAvailableForRow(rowIndex, 0);
      _setCurrentValueBaselineForRow(rowIndex, null);
      _descriptionControllerForRow(rowIndex).clear();
      _adjustedControllerForRow(rowIndex).clear();
      _newOnHandControllerForRow(rowIndex).clear();
      _lineCostPrices.remove(rowIndex);
      _lineReportingTags[rowIndex] = <String, String?>{};
      _selectedLineItems[rowIndex] = false;
      _rowBatchResults.remove(rowIndex);
      if (_hoveredItemRowIndex == rowIndex) {
        _hoveredItemRowIndex = null;
      }
    });
    if (_openReportingTagsRowIndex == rowIndex) {
      _hideReportingTagsUnavailablePopover();
    }
    if (_openCostPriceRowIndex == rowIndex) {
      _hideCostPricePopover();
    }
    _hideRowActionsMenu();
  }

  void _deleteRow(int rowIndex) {
    setState(() {
      if (_rowOrder.length <= 1) {
        _setSelectedProductForRow(rowIndex, null);
        _setQuantityAvailableForRow(rowIndex, 0);
        _setCurrentValueBaselineForRow(rowIndex, null);
        _descriptionControllerForRow(rowIndex).clear();
        _adjustedControllerForRow(rowIndex).clear();
        _newOnHandControllerForRow(rowIndex).clear();
        _selectedLineItems[rowIndex] = false;
        _lineCostPrices.remove(rowIndex);
        _lineReportingTags[rowIndex] = <String, String?>{};
        _rowBatchResults.remove(rowIndex);
      } else {
        _rowOrder.remove(rowIndex);
        _selectedLineItems[rowIndex] = false;
        _lineCostPrices.remove(rowIndex);
        _lineReportingTags.remove(rowIndex);
        _rowBatchResults.remove(rowIndex);
        _extraSelectedProducts.remove(rowIndex);
        _extraQuantitiesAvailable.remove(rowIndex);
        _extraCurrentValueBaselines.remove(rowIndex);
        _extraDescriptionControllers.remove(rowIndex)?.dispose();
        _extraAdjustedControllers.remove(rowIndex)?.dispose();
        _extraNewOnHandControllers?.remove(rowIndex)?.dispose();
        if (_hoveredItemRowIndex == rowIndex) {
          _hoveredItemRowIndex = null;
        }
      }
    });
    if (_openReportingTagsRowIndex == rowIndex) {
      _hideReportingTagsUnavailablePopover();
    }
    if (_openCostPriceRowIndex == rowIndex) {
      _hideCostPricePopover();
    }
    _hideRowActionsMenu();
  }

  void _insertNewRow({int? afterRowIndex}) {
    if (_rowOrder.any((rowIndex) => _productForRow(rowIndex) == null)) {
      return;
    }
    final newRowIndex = _nextRowId++;
    _ensureRowInfrastructure(newRowIndex);
    setState(() {
      final insertAt = afterRowIndex == null
          ? _rowOrder.length
          : _rowOrder.indexOf(afterRowIndex) + 1;
      if (insertAt <= 0 || insertAt > _rowOrder.length) {
        _rowOrder.add(newRowIndex);
      } else {
        _rowOrder.insert(insertAt, newRowIndex);
      }
      _lineCostPrices.remove(newRowIndex);
      _lineReportingTags[newRowIndex] = <String, String?>{};
      _selectedLineItems[newRowIndex] = false;
    });
  }

  bool _needsProductLabelHydration(_ProductOption? selectedProduct) {
    if (selectedProduct == null) return false;
    final name = selectedProduct.name.trim();
    if (name.isEmpty) return true;
    if (name == selectedProduct.id) return true;
    return _looksLikeUuid(name);
  }

  void _ensureTrailingBlankRowInState() {
    if (_rowOrder.any((rowIndex) => _productForRow(rowIndex) == null)) {
      return;
    }
    final newRowIndex = _nextRowId++;
    _ensureRowInfrastructure(newRowIndex);
    _rowOrder.add(newRowIndex);
    _lineCostPrices.remove(newRowIndex);
    _lineReportingTags[newRowIndex] = <String, String?>{};
    _selectedLineItems[newRowIndex] = false;
  }

  void _reorderRows(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex < 0 ||
        oldIndex >= _rowOrder.length ||
        newIndex < 0 ||
        newIndex >= _rowOrder.length) {
      return;
    }

    _hideRowActionsMenu();
    _hideReportingTagsUnavailablePopover();
    _hideCostPricePopover();

    setState(() {
      final moved = _rowOrder.removeAt(oldIndex);
      _rowOrder.insert(newIndex, moved);
      _hoveredItemRowIndex = null;
    });
  }

  Future<void> _openBulkItemsDialog({int? afterRowIndex}) async {
    if (_loadingProducts) return;
    if ((_productOptions ?? const <_ProductOption>[]).isEmpty) {
      await _loadInitialProducts();
    }
    if (!mounted) return;

    final products = _productOptions ?? const <_ProductOption>[];
    if (products.isEmpty) return;

    ref.read(itemsControllerProvider.notifier).loadLookupData();

    final items = products
        .map(
          (p) => Item(
            id: p.id,
            type: 'goods',
            productName: p.name,
            itemCode: p.code,
            unitId: '',
            categoryId: p.categoryId,
            categoryName: p.categoryName,
            primaryImageUrl: p.imageUrl,
            costPrice: p.costPrice,
            sellingPrice: p.recentPrice,
            trackBatches: p.trackBatches,
            trackBinLocation: p.trackBinLocation,
            trackSerialNumber: p.trackSerialNumber,
          ),
        )
        .toList();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => BulkItemsDialog(
        products: items,
        onItemsSelected: (selectedItems) async {
          if (!mounted || selectedItems.isEmpty) return;
          final mappedSelections = selectedItems.entries.map((e) {
            final item = e.key;
            final product = products.firstWhere((p) => p.id == item.id);
            return _BulkSelectedProduct(product: product, quantity: e.value);
          }).toList();
          await _applyBulkItemsSelection(
            mappedSelections,
            afterRowIndex: afterRowIndex,
          );
        },
      ),
    );
  }

  Future<void> _applyBulkItemsSelection(
    List<_BulkSelectedProduct> selections, {
    int? afterRowIndex,
  }) async {
    if (selections.isEmpty) return;

    final emptyRows = _rowOrder
        .where((rowIndex) => _productForRow(rowIndex) == null)
        .toList(growable: false);

    int insertPos = afterRowIndex == null
        ? _rowOrder.length
        : _rowOrder.indexOf(afterRowIndex) + 1;
    if (insertPos <= 0 || insertPos > _rowOrder.length) {
      insertPos = _rowOrder.length;
    }

    final newRowIndices = <int>[];
    int neededNewRows = selections.length - emptyRows.length;
    for (var i = 0; i < neededNewRows; i++) {
      final newRowIndex = _nextRowId++;
      _ensureRowInfrastructure(newRowIndex);
      newRowIndices.add(newRowIndex);
    }

    setState(() {
      if (newRowIndices.isNotEmpty) {
        _rowOrder.insertAll(insertPos, newRowIndices);
      }

      final targetRows = <int>[
        ...emptyRows,
        ...newRowIndices,
      ].take(selections.length).toList(growable: false);

      for (var i = 0; i < selections.length; i++) {
        final selection = selections[i];
        final targetRow = targetRows[i];
        _setSelectedProductForRow(targetRow, selection.product);
        _descriptionControllerForRow(targetRow).text =
            selection.product.description;
        _adjustedControllerForRow(targetRow).text = selection.quantity > 0
            ? '+${selection.quantity}'
            : '${selection.quantity}';
        _lineCostPrices[targetRow] =
            selection.product.costPrice ?? selection.product.recentPrice;
      }

      _ensureTrailingBlankRowInState();
    });

    await _loadQuantityAvailable();
  }

  void _showRowActionsMenu(int rowIndex) {
    if (_productForRow(rowIndex) != null) {
      _hideBulkActionsMenu();
      _hideReportingTagsUnavailablePopover();
      _hideCostPricePopover();
      _hideRowActionsMenu();
      _openRowActionsRowIndex = rowIndex;
      _rowActionsOverlay = OverlayEntry(
        builder: (overlayContext) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _hideRowActionsMenu,
                  child: const SizedBox.expand(),
                ),
              ),
              CompositedTransformFollower(
                link: _rowActionsLayerLinks[rowIndex],
                showWhenUnlinked: false,
                targetAnchor: Alignment.centerLeft,
                followerAnchor: Alignment.centerRight,
                offset: const Offset(-8, 0),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 172,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 42,
                      child: FilledButton.icon(
                        onPressed: () {
                          _hideRowActionsMenu();
                          _openItemDetailsDrawerForRow(rowIndex);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(LucideIcons.briefcase, size: 15),
                        label: const Text(
                          'View Item Details',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
      Overlay.of(context).insert(_rowActionsOverlay!);
      return;
    }
    _hideBulkActionsMenu();
    _hideReportingTagsUnavailablePopover();
    _hideCostPricePopover();
    _hideRowActionsMenu();
    _openRowActionsRowIndex = rowIndex;
    _rowActionsOverlay = OverlayEntry(
      builder: (overlayContext) {
        Widget buildMenuItem({
          required String keyName,
          required String label,
          required VoidCallback onTap,
        }) {
          final hovered = _hoveredRowAction == keyName;
          return MouseRegion(
            onEnter: (_) {
              _hoveredRowAction = keyName;
              _rowActionsOverlay?.markNeedsBuild();
            },
            onExit: (_) {
              if (_hoveredRowAction == keyName) {
                _hoveredRowAction = null;
                _rowActionsOverlay?.markNeedsBuild();
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _hideRowActionsMenu();
                onTap();
              },
              child: Container(
                height: 34,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: hovered ? AppTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hovered ? FontWeight.w600 : FontWeight.w400,
                    color: hovered ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideRowActionsMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _rowActionsLayerLinks[rowIndex],
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 226,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildMenuItem(
                        keyName: 'toggle-additional-$rowIndex',
                        label: _showAllAdditionalInformation
                            ? 'Hide Additional Information'
                            : 'Show Additional Information',
                        onTap: () {
                          setState(() {
                            _showAllAdditionalInformation =
                                !_showAllAdditionalInformation;
                          });
                        },
                      ),
                      buildMenuItem(
                        keyName: 'insert-row-$rowIndex',
                        label: 'Insert New Row',
                        onTap: () {
                          _insertNewRow(afterRowIndex: rowIndex);
                        },
                      ),
                      buildMenuItem(
                        keyName: 'insert-bulk-$rowIndex',
                        label: 'Insert Items in Bulk',
                        onTap: () {
                          _toast(
                            'Bulk item import will be enabled in the next iteration.',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_rowActionsOverlay!);
  }

  void _showBulkActionsMenu() {
    _hideReportingTagsUnavailablePopover();
    _hideCostPricePopover();
    _bulkActionsOverlay = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideBulkActionsMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _bulkActionsLayerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 4),
              child: StatefulBuilder(
                builder: (context, setOverlayState) {
                  Widget buildMenuItem({
                    required String keyName,
                    required String label,
                    required VoidCallback onTap,
                  }) {
                    final hovered = _hoveredBulkAction == keyName;
                    return MouseRegion(
                      onEnter: (_) {
                        setOverlayState(() {
                          _hoveredBulkAction = keyName;
                        });
                      },
                      onExit: (_) {
                        setOverlayState(() {
                          if (_hoveredBulkAction == keyName) {
                            _hoveredBulkAction = null;
                          }
                        });
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _hideBulkActionsMenu();
                          onTap();
                        },
                        child: Container(
                          height: 32,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: hovered
                                ? AppTheme.primaryBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: hovered
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: hovered
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 244,
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildMenuItem(
                            keyName: 'bulk-update',
                            label: 'Bulk Update Line Items',
                            onTap: () {
                              _activateBulkSelectionMode(selectAll: true);
                            },
                          ),
                          buildMenuItem(
                            keyName: 'toggle-additional',
                            label: _showAllAdditionalInformation
                                ? 'Hide All Additional Information'
                                : 'Show All Additional Information',
                            onTap: () {
                              setState(() {
                                _showAllAdditionalInformation =
                                    !_showAllAdditionalInformation;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_bulkActionsOverlay!);
  }

  Future<void> _openItemDetailsDrawerForRow(int rowIndex) async {
    final selectedProduct = _productForRow(rowIndex);
    if (selectedProduct == null || selectedProduct.id.isEmpty) {
      return;
    }

    try {
      final item = await ref
          .read(itemsControllerProvider.notifier)
          .ensureItemLoaded(selectedProduct.id);
      if (!mounted) return;
      if (item == null) {
        _toast('Failed to load item details.');
        return;
      }
      ref.read(itemDetailsSidebarProvider.notifier).state = item;
      _scaffoldKey.currentState?.openEndDrawer();
    } catch (_) {
      if (!mounted) return;
      _toast('Failed to load item details.');
    }
  }

  void _showBulkUpdateLineItemsDialog() {
    final accentColor = ref.read(appBrandingProvider).accentColor;
    if (!_hasSelectedLineItems) {
      _toast('Please select at least one line item.');
      return;
    }

    if (_reportingTagOptions.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            alignment: Alignment.topCenter,
            insetPadding: EdgeInsets.zero,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: 700,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Bulk Update Line Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            LucideIcons.x,
                            size: 18,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderColor),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 48),
                    child: Text(
                      "There are no active reporting tags or you haven't created a reporting tag yet. You can create/edit reporting tags under Settings.",
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderColor),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    child: Row(
                      children: [
                        FilledButton(
                          onPressed: null,
                          style: FilledButton.styleFrom(
                            disabledBackgroundColor: accentColor,
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text('Update'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: accentColor),
                            foregroundColor: accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text('Cancel'),
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
      return;
    }

    final Map<String, String?> values = <String, String?>{
      for (final key in _reportingTagOptions.keys) key: 'None',
    };

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 700,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Bulk Update Line Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(
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
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select an option in the reporting tags to update them for all the selected line items.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 18,
                            runSpacing: 16,
                            children: _reportingTagOptions.entries.map((entry) {
                              return SizedBox(
                                width: 306,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FormDropdown<String>(
                                      value: values[entry.key],
                                      items: entry.value,
                                      hint: 'None',
                                      onChanged: (value) {
                                        setDialogState(() {
                                          values[entry.key] = value ?? 'None';
                                        });
                                      },
                                      forceUppercase: false,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Note: Only the reporting tags you select will be updated in the line items. Other tags will not be updated.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                      child: Row(
                        children: [
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                for (final rowIndex in _rowOrder) {
                                  if (!_selectedLineItems[rowIndex]) continue;
                                  final rowTags = _lineReportingTags
                                      .putIfAbsent(
                                        rowIndex,
                                        () => <String, String?>{},
                                      );
                                  for (final entry in values.entries) {
                                    if (entry.value != null &&
                                        entry.value!.trim().isNotEmpty &&
                                        entry.value != 'None') {
                                      rowTags[entry.key] = entry.value;
                                    }
                                  }
                                }
                              });
                              Navigator.of(dialogContext).pop();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Update'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Cancel'),
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
    );
  }

  void _hideReportingTagsUnavailablePopover() {
    _reportingTagsOverlay?.remove();
    _reportingTagsOverlay = null;
    _openReportingTagsRowIndex = null;
  }

  void _hideCostPricePopover() {
    _costPriceOverlay?.remove();
    _costPriceOverlay = null;
    _openCostPriceRowIndex = null;
  }

  void _showReportingTagsPopover(int rowIndex) {
    final accentColor = ref.read(appBrandingProvider).accentColor;
    _hideCostPricePopover();
    if (_openReportingTagsRowIndex == rowIndex &&
        _reportingTagsOverlay != null) {
      _hideReportingTagsUnavailablePopover();
      return;
    }

    _hideReportingTagsUnavailablePopover();
    _openReportingTagsRowIndex = rowIndex;

    _reportingTagsOverlay = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideReportingTagsUnavailablePopover,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _reportingTagLayerLinks[rowIndex],
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(16, 2),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Reporting Tags',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: _hideReportingTagsUnavailablePopover,
                                  child: Icon(
                                    LucideIcons.x,
                                    size: 16,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppTheme.borderColor),
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: _reportingTagOptions.entries.map((
                                  entry,
                                ) {
                                  final category = entry.key;
                                  final options = entry.value;
                                  final currentVal =
                                      _lineReportingTags[rowIndex]?[category] ??
                                      'None';

                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textSecondary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        FormDropdown<String>(
                                          value: options.contains(currentVal)
                                              ? currentVal
                                              : 'None',
                                          items: ['None', ...options],
                                          height: 32,
                                          showSearch: options.length > 5,
                                          onChanged: (val) {
                                            setState(() {
                                              _lineReportingTags[rowIndex] ??=
                                                  {};
                                              _lineReportingTags[rowIndex]![category] =
                                                  val == 'None' ? null : val;
                                            });
                                            setOverlayState(() {});
                                          },
                                          displayStringForValue: (v) => v,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: AppTheme.borderColor),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: ZButton.primary(
                              label: 'Apply Tags',
                              onPressed: _hideReportingTagsUnavailablePopover,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_reportingTagsOverlay!);
  }

  void _showCostPricePopover(int rowIndex) {
    final accentColor = ref.read(appBrandingProvider).accentColor;
    _hideReportingTagsUnavailablePopover();
    if (_openCostPriceRowIndex == rowIndex && _costPriceOverlay != null) {
      _hideCostPricePopover();
      return;
    }

    _hideCostPricePopover();
    _openCostPriceRowIndex = rowIndex;
    final rowProduct = _productForRow(rowIndex);
    final recentTransactionPrice =
        rowProduct?.recentPrice ?? rowProduct?.costPrice;

    final controller = TextEditingController(
      text: _effectiveCostPriceForRow(rowIndex).toStringAsFixed(0),
    );

    _costPriceOverlay = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideCostPricePopover,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _costPriceLayerLinks[rowIndex],
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -8,
                      left: 66,
                      child: Transform.rotate(
                        angle: 0.785398,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 304,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: StatefulBuilder(
                        builder: (context, setOverlayState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  10,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Cost Price',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _hideCostPricePopover,
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: accentColor,
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.x,
                                          size: 16,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.borderColor,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: AppTheme.borderColor,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          '\u20B9',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: controller,
                                          autofocus: true,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9.]'),
                                            ),
                                          ],
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 9,
                                                ),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textPrimary,
                                          ),
                                          onChanged: (_) {
                                            setOverlayState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'If the cost price is set to 0, the system will not automatically update the cost price based on recent transactions.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.45,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  10,
                                ),
                                child: recentTransactionPrice == null
                                    ? const SizedBox.shrink()
                                    : RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                          children: [
                                            TextSpan(
                                              text:
                                                  'Recent Price: ${_formatCurrency(recentTransactionPrice)} ',
                                            ),
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.middle,
                                              child: GestureDetector(
                                                onTap: () {
                                                  controller.text =
                                                      recentTransactionPrice ==
                                                          recentTransactionPrice
                                                              .roundToDouble()
                                                      ? recentTransactionPrice
                                                            .toStringAsFixed(0)
                                                      : recentTransactionPrice
                                                            .toStringAsFixed(2);
                                                  setOverlayState(() {});
                                                },
                                                child: Text(
                                                  'Apply',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.primaryBlue,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  14,
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    _hideCostPricePopover();
                                    await _openItemDetailsDrawerForRow(
                                      rowIndex,
                                    );
                                  },
                                  child: Text(
                                    'View Purchase Information',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Row(
                                  children: [
                                    FilledButton(
                                      onPressed: () {
                                        final parsed = double.tryParse(
                                          controller.text.trim(),
                                        );
                                        setState(() {
                                          _lineCostPrices[rowIndex] =
                                              parsed ?? 0;
                                        });
                                        _hideCostPricePopover();
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: accentColor,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(98, 38),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Update'),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton(
                                      onPressed: _hideCostPricePopover,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.textPrimary,
                                        minimumSize: const Size(90, 38),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        side: const BorderSide(
                                          color: AppTheme.borderColor,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_costPriceOverlay!);
  }

  void _showManageReasonsDialog() {
    final TextEditingController reasonController = TextEditingController();
    bool showCreateForm = false;
    int? hoveredReasonIndex;

    String _extractReasonError(Object error) {
      final lower = error.toString().toLowerCase();
      if (lower.contains('already used') ||
          lower.contains('in use') ||
          lower.contains('foreign key') ||
          lower.contains('constraint')) {
        return 'You cannot delete this reason as it is already used in an adjustment. Mark it as inactive instead.';
      }
      if (lower.contains('global default reasons cannot be deleted')) {
        return 'Global default reasons cannot be deleted.';
      }
      return 'Failed to delete reason';
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              child: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Manage Reasons',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(
                              LucideIcons.x,
                              size: 20,
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!showCreateForm)
                            FilledButton(
                              onPressed: () {
                                setDialogState(() => showCreateForm = true);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text('+ Add new reason'),
                            ),
                          if (showCreateForm) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text.rich(
                                    TextSpan(
                                      text: 'Reason',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.errorRed,
                                      ),
                                      children: [TextSpan(text: '*')],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 340,
                                    child: CustomTextField(
                                      controller: reasonController,
                                      hintText: '',
                                      forceUppercase: false,
                                      contentCase: ContentCase.sentence,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      FilledButton(
                                        onPressed: () async {
                                          final value = reasonController.text
                                              .trim();
                                          if (value.isEmpty) return;
                                          try {
                                            final repo = ref.read(
                                              adjustmentsRepositoryProvider,
                                            );
                                            final created = await repo
                                                .createAdjustmentReason(value);
                                            if (!mounted) return;
                                            setState(() {
                                              _reasonOptions.insert(0, created);
                                              _selectedReason = created.name;
                                            });
                                            setDialogState(() {
                                              showCreateForm = false;
                                              reasonController.clear();
                                            });
                                            Navigator.of(dialogContext).pop();
                                          } catch (_) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Failed to save reason',
                                                  ),
                                                ),
                                              );
                                          }
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.successGreen,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Save and Select'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            showCreateForm = false;
                                            reasonController.clear();
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: AppTheme.borderColor,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Cancel'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            height: 360,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderColor),
                              color: Colors.white,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  color: AppTheme.tableHeaderBg,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: const Text(
                                    'REASON',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: _reasonOptions.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: AppTheme.borderColor,
                                    ),
                                    itemBuilder: (context, index) {
                                      final reason = _reasonOptions[index];
                                      final isHovered =
                                          hoveredReasonIndex == index;
                                      return MouseRegion(
                                        onEnter: (_) {
                                          setDialogState(
                                            () => hoveredReasonIndex = index,
                                          );
                                        },
                                        onExit: (_) {
                                          setDialogState(
                                            () => hoveredReasonIndex = null,
                                          );
                                        },
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedReason = reason.name;
                                            });
                                            Navigator.of(dialogContext).pop();
                                          },
                                          child: Container(
                                            color: isHovered
                                                ? AppTheme.bgLight
                                                : Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 11,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    reason.isActive
                                                        ? reason.name
                                                        : '${reason.name}   [INACTIVE]',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: reason.isActive
                                                          ? AppTheme.textPrimary
                                                          : AppTheme
                                                                .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                if (isHovered &&
                                                    !reason.isGlobal)
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        onTap: () async {
                                                          try {
                                                            final repo = ref.read(
                                                              adjustmentsRepositoryProvider,
                                                            );
                                                            final updated = await repo
                                                                .updateAdjustmentReason(
                                                                  reason.id,
                                                                  isActive: !reason
                                                                      .isActive,
                                                                );
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            setState(() {
                                                              _reasonOptions[index] =
                                                                  updated;
                                                            });
                                                            setDialogState(
                                                              () {},
                                                            );
                                                            _toast(
                                                              updated.isActive
                                                                  ? 'Reason marked active.'
                                                                  : 'Reason marked inactive.',
                                                              success: true,
                                                            );
                                                          } catch (_) {
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            _toast(
                                                              'Failed to update reason',
                                                            );
                                                          }
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 4,
                                                                vertical: 2,
                                                              ),
                                                          child: Text(
                                                            reason.isActive
                                                                ? 'Mark as Inactive'
                                                                : 'Mark as Active',
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              color: AppTheme
                                                                  .textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        onTap: () async {
                                                          try {
                                                            final repo = ref.read(
                                                              adjustmentsRepositoryProvider,
                                                            );
                                                            await repo
                                                                .deleteAdjustmentReason(
                                                                  reason.id,
                                                                );
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            setState(() {
                                                              _reasonOptions
                                                                  .removeAt(
                                                                    index,
                                                                  );
                                                              if (_selectedReason ==
                                                                  reason.name) {
                                                                _selectedReason =
                                                                    null;
                                                              }
                                                            });
                                                            setDialogState(
                                                              () {},
                                                            );
                                                            _toast(
                                                              'Reason deleted.',
                                                              success: true,
                                                            );
                                                          } catch (error) {
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            _toast(
                                                              _extractReasonError(
                                                                error,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 2,
                                                                vertical: 2,
                                                              ),
                                                          child: Icon(
                                                            LucideIcons.trash2,
                                                            size: 14,
                                                            color: AppTheme
                                                                .errorRed,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
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
    ).whenComplete(reasonController.dispose);
  }

  Widget _buildAttachmentSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: SizedBox(
        width: 1048,
        child: AttachmentSection(
          title: 'Attach file(s) to inventory adjustment',
          files: _attachedFiles,
          onFilesChanged: (updated) => setState(() => _attachedFiles = updated),
          maxFiles: 5,
          allowedExtensions: const <String>['pdf', 'jpg', 'jpeg', 'png'],
          titleFontSize: 13,
          helperFontSize: 11,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final bool isEditMode = _editingSourceId != null && !widget.isClone;
    final String primaryActionLabel = _mode == 'quantity'
        ? 'Convert to Adjusted'
        : 'Approve and Adjust';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          if (isEditMode) ...[
            ZButton.primary(
              label: _saving ? 'Saving...' : 'Save',
              onPressed: _saving ? null : () => _submit('approved'),
            ),
            const SizedBox(width: 10),
          ] else ...[
            ZButton.primary(
              label: _saving ? 'Saving...' : 'Save as Draft',
              onPressed: _saving ? null : () => _submit('draft'),
            ),
            const SizedBox(width: 10),
            _buildSplitButton(primaryActionLabel),
            const SizedBox(width: 10),
          ],
          ZButton.secondary(label: 'Cancel', onPressed: _goBack),
        ],
      ),
    );
  }

  /// Split button: main action (Approve and Adjust / Convert to Adjusted) +
  /// dropdown arrow revealing "Save and Submit".
  Widget _buildSplitButton(String primaryLabel) {
    return ZSplitActionMenuButton(
      height: 38,
      triggerLabel: primaryLabel,
      onPrimaryPressed: () => _submit('approved'),
      isDisabled: _saving,
      isPrimaryStyle: false,
      useFilledBlueHover: false,
      menuItems: [
        ZSplitActionMenuItem(
          label: 'Save and Submit',
          onPressed: () => _submit('submitted'),
        ),
      ],
    );
  }

  Widget _buildFormRow({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _formLabelWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text.rich(
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 13,
                    color: required ? AppTheme.errorRed : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  children: required
                      ? const [TextSpan(text: '*', style: TextStyle())]
                      : const <TextSpan>[],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _field(Widget child) => SizedBox(width: _fieldWidth, child: child);
}

class _TableHeader extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _TableHeader(this.text, {this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    final isRequired = text.contains('*');
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 0.35,
        fontWeight: FontWeight.w700,
        color: isRequired ? AppTheme.errorRed : AppTheme.textSecondary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
    );
  }
}

enum _MetricCellType { first, second }

class _AccountRow {
  final String id;
  final String name;
  final String? parentId;
  final String accountType;
  final String accountGroup;
  final bool isActive;
  final bool isDeleted;

  const _AccountRow({
    required this.id,
    required this.name,
    required this.parentId,
    required this.accountType,
    required this.accountGroup,
    required this.isActive,
    required this.isDeleted,
  });

  factory _AccountRow.fromJson(Map<String, dynamic> json) {
    String pickName() {
      final candidates = <dynamic>[
        json['user_account_name'],
        json['userAccountName'],
        json['account_name'],
        json['accountName'],
        json['name'],
        json['label'],
        json['title'],
        json['system_account_name'],
        json['systemAccountName'],
      ];
      for (final c in candidates) {
        final v = c?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final rawType = (json['account_type'] ?? json['accountType'] ?? 'Other')
        .toString()
        .trim();
    final rawGroup = (json['account_group'] ?? json['accountGroup'] ?? 'Other')
        .toString()
        .trim();
    final parentRaw = (json['parent_id'] ?? json['parentId'])
        ?.toString()
        .trim();

    return _AccountRow(
      id: (json['id'] ?? '').toString().trim(),
      name: pickName(),
      parentId: (parentRaw == null || parentRaw.isEmpty) ? null : parentRaw,
      accountType: rawType.isEmpty ? 'Other' : rawType,
      accountGroup: rawGroup.isEmpty ? 'Other' : rawGroup,
      isActive: json['is_active'] != false && json['isActive'] != false,
      isDeleted: json['is_deleted'] == true || json['isDeleted'] == true,
    );
  }
}

class _BulkSelectedProduct {
  final _ProductOption product;
  final int quantity;

  const _BulkSelectedProduct({required this.product, required this.quantity});
}

class _ProductOption {
  final String id;
  final String name;
  final String code;
  final String description;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final double? costPrice;
  final double? recentPrice;
  final bool trackBatches;
  final bool trackBinLocation;
  final bool trackSerialNumber;

  const _ProductOption({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.costPrice,
    this.recentPrice,
    this.trackBatches = false,
    this.trackBinLocation = false,
    this.trackSerialNumber = false,
  });

  factory _ProductOption.fromJson(Map<String, dynamic> json) {
    final description =
        (json['sales_description'] ??
                json['salesDescription'] ??
                json['purchase_description'] ??
                json['purchaseDescription'] ??
                json['description'] ??
                '')
            .toString();
    double? parseNum(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse((value ?? '').toString());
    }

    final costPrice =
        parseNum(json['cost_price']) ??
        parseNum(json['purchase_price']) ??
        parseNum(json['purchasePrice']) ??
        parseNum(json['purchase_rate']) ??
        parseNum(json['purchaseRate']) ??
        parseNum(json['default_purchase_price']) ??
        parseNum(json['defaultPurchasePrice']);
    final recentPrice =
        parseNum(json['recent_price']) ??
        parseNum(json['recentPrice']) ??
        costPrice;

    String? pickCategoryId() {
      final direct =
          json['category_id'] ??
          json['categoryId'] ??
          json['item_category_id'] ??
          json['itemCategoryId'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString().trim();
      }
      final category = json['category'];
      if (category is Map) {
        final nested = category['id'] ?? category['category_id'];
        if (nested != null && nested.toString().trim().isNotEmpty) {
          return nested.toString().trim();
        }
      }
      return null;
    }

    String? pickCategoryName() {
      final direct =
          json['category_name'] ??
          json['categoryName'] ??
          json['item_category_name'] ??
          json['itemCategoryName'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString().trim();
      }
      final category = json['category'];
      if (category is Map) {
        final nested =
            category['name'] ??
            category['category_name'] ??
            category['label'] ??
            category['title'];
        if (nested != null && nested.toString().trim().isNotEmpty) {
          return nested.toString().trim();
        }
      }
      return null;
    }

    return _ProductOption(
      id: (json['id'] ?? '').toString(),
      name: (json['product_name'] ?? json['name'] ?? '').toString(),
      code: (json['item_code'] ?? json['sku'] ?? '').toString(),
      description: description,
      categoryId: pickCategoryId(),
      categoryName: pickCategoryName(),
      imageUrl:
          json['image_url']?.toString() ??
          json['primary_image_url']?.toString(),
      costPrice: costPrice,
      recentPrice: recentPrice,
      trackBatches:
          json['track_batches'] == true || json['trackBatches'] == true,
      trackBinLocation:
          json['track_bin_location'] == true ||
          json['trackBinLocation'] == true,
      trackSerialNumber:
          json['track_serial_number'] == true ||
          json['trackSerialNumber'] == true,
    );
  }
}

// ─── Inventory Adjustment – Add Batches dialog (private) ────────────────────

class _AdjBatch {
  final String batchId;
  final String batchReference;
  final String? binId;
  final double quantity;
  final String? unitPack;
  final double? mrp;
  final DateTime? expiryDate;
  final DateTime? mfdDate;

  const _AdjBatch({
    required this.batchId,
    required this.batchReference,
    this.binId,
    required this.quantity,
    this.unitPack,
    this.mrp,
    this.expiryDate,
    this.mfdDate,
  });
}

class _AdjBatchDialogResult {
  final List<_AdjBatch> batches;
  final double totalQuantity;
  final bool overwriteLineItem;

  const _AdjBatchDialogResult({
    required this.batches,
    required this.totalQuantity,
    this.overwriteLineItem = true,
  });
}

class _AdjBatchRowController {
  String id;
  bool isExistingBatchSelection;
  final TextEditingController binController;
  final TextEditingController batchRefController;
  final TextEditingController unitPackController;
  final TextEditingController mrpController;
  final TextEditingController mfrBatchController;
  final TextEditingController mfdController;
  final TextEditingController expiryController;
  final TextEditingController quantityController;
  final TextEditingController focController;
  final GlobalKey expiryFieldKey = GlobalKey();
  final GlobalKey mfdFieldKey = GlobalKey();
  final FocusNode batchRefFocus = FocusNode();
  final LayerLink layerLink = LayerLink();
  String? selectedBinId;
  DateTime? mfdDate;
  DateTime? expiryDate;
  double? availableBalance;

  _AdjBatchRowController({
    required this.id,
    this.isExistingBatchSelection = false,
    String? binRef,
    String? batchRef,
    String? unitPack,
    String? mrp,
    String? mfrBatch,
    DateTime? mfd,
    DateTime? expiry,
    double? qty,
    String? foc,
    this.selectedBinId,
  }) : binController = TextEditingController(text: binRef ?? ''),
       batchRefController = TextEditingController(text: batchRef),
       unitPackController = TextEditingController(text: unitPack ?? ''),
       mrpController = TextEditingController(text: mrp ?? ''),
       mfrBatchController = TextEditingController(text: mfrBatch ?? ''),
       mfdController = TextEditingController(
         text: mfd != null ? DateFormat('MM/yyyy').format(mfd) : '',
       ),
       expiryController = TextEditingController(
         text: expiry != null ? DateFormat('MM/yyyy').format(expiry) : '',
       ),
       quantityController = TextEditingController(text: qty?.toString() ?? ''),
       focController = TextEditingController(text: foc ?? ''),
       mfdDate = mfd,
       expiryDate = expiry;

  void dispose() {
    binController.dispose();
    batchRefController.dispose();
    unitPackController.dispose();
    mrpController.dispose();
    mfrBatchController.dispose();
    mfdController.dispose();
    expiryController.dispose();
    quantityController.dispose();
    focController.dispose();
    batchRefFocus.dispose();
  }
}

class _AdjAddBatchesDialog extends ConsumerStatefulWidget {
  final String productName;
  final String warehouseId;
  final String warehouseName;
  final double totalQuantity;
  final bool isOutAdjustment;
  final List<_AdjBatch>? savedBatches;
  final String itemId;
  final Future<List<Map<String, dynamic>>> Function(
    String productId,
    String query,
  )
  onFetchBatchSuggestions;

  const _AdjAddBatchesDialog({
    required this.productName,
    required this.warehouseId,
    required this.warehouseName,
    required this.totalQuantity,
    required this.isOutAdjustment,
    this.savedBatches,
    required this.itemId,
    required this.onFetchBatchSuggestions,
  });

  @override
  ConsumerState<_AdjAddBatchesDialog> createState() =>
      _AdjAddBatchesDialogState();
}

class _AdjAddBatchesDialogState extends ConsumerState<_AdjAddBatchesDialog> {
  final List<_AdjBatchRowController> _rows = [];
  bool _showManufactureDetails = false;
  bool _showFocColumn = false;
  bool _overwriteLineItem = false;
  bool _triedSaving = false;
  OverlayEntry? _searchOverlay;
  Timer? _searchDebounce;
  final Map<String, double> _batchBalanceById = <String, double>{};

  @override
  void initState() {
    super.initState();
    if (widget.savedBatches != null && widget.savedBatches!.isNotEmpty) {
      for (final b in widget.savedBatches!) {
        final savedBatchId = b.batchId.trim();
        _rows.add(
          _AdjBatchRowController(
            id: savedBatchId,
            isExistingBatchSelection: savedBatchId.isNotEmpty,
            batchRef: b.batchReference,
            unitPack: b.unitPack,
            mrp: b.mrp != null ? b.mrp!.toStringAsFixed(0) : null,
            mfd: b.mfdDate,
            expiry: b.expiryDate,
            qty: b.quantity,
            selectedBinId: b.binId,
          ),
        );
      }
      _hydrateSavedBatchLabels();
    } else {
      _addNewRow();
    }
  }

  Future<void> _hydrateSavedBatchLabels() async {
    try {
      final combinedRaw = <Map<String, dynamic>>[];
      final seenKeys = <String>{};

      void appendRows(List<Map<String, dynamic>> rows) {
        for (final row in rows) {
          final id = (row['id'] ?? '').toString().trim();
          final batchNo = (row['batch_no'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final key = id.isNotEmpty ? 'id:$id' : 'batch:$batchNo';
          if (key == 'batch:' || seenKeys.contains(key)) continue;
          seenKeys.add(key);
          combinedRaw.add(row);
        }
      }

      final initial = await widget.onFetchBatchSuggestions(widget.itemId, '');
      if (!mounted) return;
      appendRows(initial);

      for (final row in _rows) {
        final ref = row.batchRefController.text.trim();
        if (ref.isEmpty) continue;
        final targeted = await widget.onFetchBatchSuggestions(
          widget.itemId,
          ref,
        );
        if (!mounted) return;
        appendRows(targeted);
      }

      if (combinedRaw.isEmpty) return;
      final options = combinedRaw
          .map((e) => BatchLookup(e))
          .toList(growable: false);
      final byId = <String, BatchLookup>{};
      final byBatchNo = <String, BatchLookup>{};
      for (final option in options) {
        final id = (option.data['id'] ?? '').toString().trim();
        if (id.isNotEmpty) byId[id] = option;
        final batchNo = option.batchNo.trim().toLowerCase();
        if (batchNo.isNotEmpty) byBatchNo[batchNo] = option;
      }

      bool changed = false;
      for (final row in _rows) {
        final id = row.id.trim();
        BatchLookup? match = id.isNotEmpty ? byId[id] : null;
        if (match == null) {
          final ref = row.batchRefController.text.trim().toLowerCase();
          if (ref.isNotEmpty) {
            match = byBatchNo[ref];
          }
        }
        if (match == null) continue;

        if (row.batchRefController.text.trim().isEmpty ||
            row.batchRefController.text.trim() == id) {
          row.batchRefController.text = match.batchNo;
          changed = true;
        }
        if (row.id.trim().isEmpty) {
          row.id = (match.data['id'] ?? '').toString().trim();
          changed = true;
        }
        if (row.unitPackController.text.trim().isEmpty) {
          final v = match.data['unit_pack']?.toString() ?? '';
          row.unitPackController.text = v;
          if (v.isNotEmpty) changed = true;
        }
        if (row.mrpController.text.trim().isEmpty && match.mrp != null) {
          row.mrpController.text = match.mrp!.toStringAsFixed(0);
          changed = true;
        }
        if (row.availableBalance == null && match.quantityAvailable != null) {
          row.availableBalance = match.quantityAvailable;
          changed = true;
        }
        row.isExistingBatchSelection = row.id.trim().isNotEmpty;
      }
      if (changed && mounted) {
        setState(() {});
      }
    } catch (_) {
      // Keep dialog usable even if lookup hydration fails.
    }
  }

  void _addNewRow() {
    setState(() {
      _rows.add(
        _AdjBatchRowController(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
    });
  }

  void _onBatchRefChanged(int index, String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      try {
        final raw = await widget.onFetchBatchSuggestions(widget.itemId, val);
        if (!mounted) return;
        if (raw.isNotEmpty) {
          _showSearchOverlay(index, raw);
        } else {
          _hideSearchOverlay();
        }
      } catch (_) {
        if (mounted) _hideSearchOverlay();
      }
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  double get _currentTotal => _rows.fold(
    0,
    (sum, row) => sum + (double.tryParse(row.quantityController.text) ?? 0),
  );

  Future<void> _pickBatchMonthYear({
    required _AdjBatchRowController row,
    required bool isExpiry,
  }) async {
    if (row.isExistingBatchSelection) return;

    final initialDate = isExpiry
        ? (row.expiryDate ?? DateTime.now())
        : (row.mfdDate ?? DateTime.now());
    final targetKey = isExpiry ? row.expiryFieldKey : row.mfdFieldKey;

    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: initialDate,
      targetKey: targetKey,
    );
    if (picked == null || !mounted) return;

    final normalized = DateTime(picked.year, picked.month, 1);
    setState(() {
      if (isExpiry) {
        row.expiryDate = normalized;
        row.expiryController.text = DateFormat('MM/yyyy').format(normalized);
      } else {
        row.mfdDate = normalized;
        row.mfdController.text = DateFormat('MM/yyyy').format(normalized);
      }
    });
  }

  void _showSearchOverlay(int index, List<Map<String, dynamic>> rawOptions) {
    _hideSearchOverlay();
    if (rawOptions.isEmpty) return;
    final options = rawOptions.map((e) => BatchLookup(e)).toList();
    final link = _rows[index].layerLink;

    _searchOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideSearchOverlay,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              child: Container(
                width: 185,
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final b = options[i];
                    return ListTile(
                      dense: true,
                      title: Text(b.batchNo),
                      subtitle:
                          widget.isOutAdjustment && b.quantityAvailable != null
                          ? Text(
                              'Balance in batch: ${b.quantityAvailable!.toStringAsFixed(0)} pcs',
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          final row = _rows[index];
                          row.id = b.data['id']?.toString() ?? row.id;
                          row.isExistingBatchSelection = true;
                          row.batchRefController.text = b.batchNo;
                          row.availableBalance = b.quantityAvailable;
                          row.unitPackController.text =
                              b.data['unit_pack']?.toString() ?? '';
                          row.mrpController.text = b.mrp != null
                              ? b.mrp!.toStringAsFixed(0)
                              : '';
                          row.mfdDate = b.mfdDate;
                          row.expiryDate = b.expiryDate;
                          row.mfdController.text = b.mfdDate != null
                              ? DateFormat('MM/yyyy').format(b.mfdDate!)
                              : '';
                          row.expiryController.text = b.expiryDate != null
                              ? DateFormat('MM/yyyy').format(b.expiryDate!)
                              : '';
                        });
                        _hideSearchOverlay();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_searchOverlay!);
    // Re-request focus after overlay insertion to prevent focus steal on Flutter Web
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && index < _rows.length) {
        _rows[index].batchRefFocus.requestFocus();
      }
    });
  }

  void _hideSearchOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _hideSearchOverlay();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compactOutMode = widget.isOutAdjustment;
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: compactOutMode ? 860 : 1160,
        height: compactOutMode
            ? 520
            : MediaQuery.of(context).size.height * 0.86,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_triedSaving &&
                _currentTotal != widget.totalQuantity &&
                !_overwriteLineItem)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorBg,
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.alertCircle,
                      size: 16,
                      color: AppTheme.errorRed,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "There's a mismatch between the quantity entered in the line item and the total quantity across all batches. Click the checkbox to overwrite the quantity",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Select Batches',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.home,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Location : ${widget.warehouseName.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Text(
                    'BATCH DETAILS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      'Item: ${widget.productName}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'Total Quantity : ${_currentTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '|',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quantity to be added : ${widget.totalQuantity.abs().toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Spacer(),
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: _overwriteLineItem,
                      onChanged: (v) =>
                          setState(() => _overwriteLineItem = v ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overwrite the line item with ${_currentTotal.toStringAsFixed(0)} quantities',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.borderColor),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTableHeader(),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _rows.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppTheme.borderColor),
                itemBuilder: (context, index) => _buildRow(index),
              ),
            ),
            // Action Links
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _addNewRow,
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.plusCircle,
                          size: 14,
                          color: AppTheme.primaryBlueDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isOutAdjustment ? 'New Row' : 'New Batch',
                          style: const TextStyle(
                            color: AppTheme.primaryBlueDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Batches added: ${_rows.length}/100',
                    style: AppTheme.captionText.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            // Bottom-Left Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ZButton.primary(
                    label: 'Save',
                    onPressed: () {
                      setState(() => _triedSaving = true);

                      // 1. Validation Logic: Only show mismatch banner on Save
                      if (_currentTotal != widget.totalQuantity &&
                          !_overwriteLineItem) {
                        return;
                      }

                      if (widget.isOutAdjustment) {
                        for (final row in _rows) {
                          final q =
                              double.tryParse(row.quantityController.text) ?? 0;
                          if (q <= 0) continue;
                          if ((row.selectedBinId == null ||
                                  row.selectedBinId!.trim().isEmpty) &&
                              row.binController.text.trim().isEmpty) {
                            ZerpaiToast.error(
                              context,
                              'Please select bin location for each selected batch.',
                            );
                            return;
                          }
                          final batchId = row.id.trim();
                          final bal =
                              row.availableBalance ??
                              (batchId.isNotEmpty
                                  ? _batchBalanceById[batchId]
                                  : null);
                          if (bal != null && q > bal) {
                            ZerpaiToast.error(
                              context,
                              'Quantity exceeds batch balance for ${row.batchRefController.text.trim().isEmpty ? 'selected batch' : row.batchRefController.text.trim()}.',
                            );
                            return;
                          }
                        }
                      }

                      final validRows = _rows.where((r) {
                        final q =
                            double.tryParse(r.quantityController.text) ?? 0;
                        if (r.batchRefController.text.isEmpty || q <= 0)
                          return false;
                        return true;
                      }).toList();

                      if (validRows.isEmpty) {
                        final message = widget.isOutAdjustment
                            ? 'Select at least one existing batch row with quantity.'
                            : 'Please add at least one valid batch row.';
                        ZerpaiToast.error(context, message);
                        return;
                      }

                      final result = _AdjBatchDialogResult(
                        totalQuantity: _currentTotal,
                        overwriteLineItem: _overwriteLineItem,
                        batches: validRows
                            .map(
                              (r) => _AdjBatch(
                                batchId: r.isExistingBatchSelection ? r.id : '',
                                batchReference: r.batchRefController.text
                                    .trim(),
                                binId: r.selectedBinId,
                                quantity:
                                    double.tryParse(
                                      r.quantityController.text,
                                    ) ??
                                    0,
                                unitPack:
                                    r.unitPackController.text.trim().isEmpty
                                    ? null
                                    : r.unitPackController.text.trim(),
                                mrp: double.tryParse(r.mrpController.text),
                                mfdDate: r.mfdDate,
                                expiryDate: r.expiryDate,
                              ),
                            )
                            .toList(),
                      );
                      Navigator.of(context).pop(result);
                    },
                  ),
                  const SizedBox(width: 12),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    if (widget.isOutAdjustment) {
      return Container(
        color: const Color(0xFFF9FAFB),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: const [
            Expanded(
              flex: 3,
              child: _TableHeader('BIN LOCATION*', align: TextAlign.left),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: _TableHeader('BATCH REFERENCE*', align: TextAlign.left),
            ),
            SizedBox(width: 10),
            Expanded(flex: 3, child: _TableHeader('QUANTITY OUT*')),
            SizedBox(width: 48),
          ],
        ),
      );
    }

    final qtyLabel = widget.isOutAdjustment ? 'QUANTITY OUT*' : 'QUANTITY IN*';
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: _TableHeader('BIN LOCATION*', align: TextAlign.left),
          ),
          const SizedBox(width: 10),
          const Expanded(
            flex: 2,
            child: _TableHeader('BATCH NO*', align: TextAlign.left),
          ),
          const SizedBox(width: 10),
          const Expanded(flex: 2, child: _TableHeader('UNIT PACK*')),
          const SizedBox(width: 10),
          const Expanded(flex: 2, child: _TableHeader('MRP*')),
          const SizedBox(width: 10),
          const Expanded(flex: 2, child: _TableHeader('EXPIRY DATE*')),
          if (_showManufactureDetails) ...[
            const SizedBox(width: 10),
            const Expanded(flex: 2, child: _TableHeader('MANUFACTURED DATE')),
            const SizedBox(width: 10),
            const Expanded(
              flex: 2,
              child: _TableHeader('MANUFACTURER BATCH', align: TextAlign.left),
            ),
          ],
          const SizedBox(width: 10),
          Expanded(flex: 2, child: _TableHeader(qtyLabel)),
          if (_showFocColumn) ...[
            const SizedBox(width: 10),
            const Expanded(flex: 1, child: _TableHeader('FOC')),
          ],
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildRow(int index) {
    final row = _rows[index];
    if (widget.isOutAdjustment) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Consumer(
                builder: (context, ref, _) {
                  final binsAsync = ref.watch(
                    _adjBinLookupProvider(widget.warehouseId),
                  );
                  final bins = binsAsync.value ?? const <BinLookup>[];
                  final savedBinId = row.selectedBinId?.trim() ?? '';
                  final effectiveBins = List<BinLookup>.from(bins);
                  if (savedBinId.isNotEmpty &&
                      !effectiveBins.any((b) => b.id == savedBinId)) {
                    final fallbackCode =
                        row.binController.text.trim().isNotEmpty
                        ? row.binController.text.trim()
                        : 'Saved Bin';
                    effectiveBins.insert(
                      0,
                      BinLookup(id: savedBinId, code: fallbackCode),
                    );
                  }
                  final selectedBin = effectiveBins.where((b) {
                    if (row.selectedBinId != null &&
                        row.selectedBinId!.trim().isNotEmpty) {
                      return b.id == row.selectedBinId!.trim();
                    }
                    return b.code == row.binController.text.trim();
                  }).firstOrNull;
                  return SizedBox(
                    height: 38,
                    child: FormDropdown<BinLookup>(
                      value: selectedBin,
                      items: effectiveBins,
                      hint: 'Select Bin',
                      showSearch: true,
                      menuMaxHeight: 220,
                      maxVisibleItems: 6,
                      displayStringForValue: (v) => v.code,
                      searchStringForValue: (v) => v.code,
                      onChanged: (val) {
                        setState(() {
                          row.binController.text = val?.code ?? '';
                          row.selectedBinId = val?.id;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: CompositedTransformTarget(
                link: row.layerLink,
                child: CustomTextField(
                  controller: row.batchRefController,
                  focusNode: row.batchRefFocus,
                  hintText: 'Select Batch',
                  suffixWidget: const Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  readOnly: true,
                  onTap: () => _onBatchRefChanged(index, ''),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: CustomTextField(
                controller: row.quantityController,
                hintText: '0',
                textAlign: TextAlign.right,
                onChanged: (_) => setState(() {}),
              ),
            ),
            Builder(
              builder: (_) {
                final qty = double.tryParse(row.quantityController.text) ?? 0;
                final bal =
                    row.availableBalance ?? _batchBalanceById[row.id.trim()];
                if (bal == null || qty <= 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 120,
                    child: qty <= bal
                        ? Text(
                            'Balance: ${bal.toStringAsFixed(0)} pcs',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          )
                        : Text(
                            'Exceeds by ${(qty - bal).toStringAsFixed(2)} pcs',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                );
              },
            ),
            IconButton(
              onPressed: () => _removeRow(index),
              icon: const Icon(
                LucideIcons.trash2,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Consumer(
              builder: (context, ref, _) {
                final binsAsync = ref.watch(
                  _adjBinLookupProvider(widget.warehouseId),
                );
                final bins = binsAsync.value ?? const <BinLookup>[];
                final savedBinId = row.selectedBinId?.trim() ?? '';
                final effectiveBins = List<BinLookup>.from(bins);
                if (savedBinId.isNotEmpty &&
                    !effectiveBins.any((b) => b.id == savedBinId)) {
                  final fallbackCode = row.binController.text.trim().isNotEmpty
                      ? row.binController.text.trim()
                      : 'Saved Bin';
                  effectiveBins.insert(
                    0,
                    BinLookup(id: savedBinId, code: fallbackCode),
                  );
                }
                final selectedBin = effectiveBins.where((b) {
                  if (row.selectedBinId != null &&
                      row.selectedBinId!.trim().isNotEmpty) {
                    return b.id == row.selectedBinId!.trim();
                  }
                  return b.code == row.binController.text.trim();
                }).firstOrNull;
                return SizedBox(
                  height: 38,
                  child: FormDropdown<BinLookup>(
                    value: selectedBin,
                    items: effectiveBins,
                    hint: 'Select Bin',
                    showSearch: true,
                    menuMaxHeight: 220,
                    maxVisibleItems: 6,
                    displayStringForValue: (v) => v.code,
                    searchStringForValue: (v) => v.code,
                    onChanged: (val) {
                      setState(() {
                        row.binController.text = val?.code ?? '';
                        row.selectedBinId = val?.id;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: CompositedTransformTarget(
              link: row.layerLink,
              child: CustomTextField(
                controller: row.batchRefController,
                focusNode: row.batchRefFocus,
                hintText: 'Select Batch',
                suffixWidget: const Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                readOnly: widget.isOutAdjustment,
                onTap: () => _onBatchRefChanged(
                  index,
                  widget.isOutAdjustment ? '' : row.batchRefController.text,
                ),
                onChanged: widget.isOutAdjustment
                    ? null
                    : (val) {
                        setState(() {
                          row.isExistingBatchSelection = false;
                        });
                        _onBatchRefChanged(index, val);
                      },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: CustomTextField(
              controller: row.unitPackController,
              hintText: 'Pack',
              textAlign: TextAlign.right,
              readOnly: row.isExistingBatchSelection,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: CustomTextField(
              controller: row.mrpController,
              hintText: '0',
              textAlign: TextAlign.right,
              readOnly: row.isExistingBatchSelection,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Container(
              key: row.expiryFieldKey,
              child: CustomTextField(
                controller: row.expiryController,
                hintText: 'MM/YYYY',
                readOnly: true,
                onTap: () => _pickBatchMonthYear(row: row, isExpiry: true),
                suffixWidget: const Icon(
                  LucideIcons.calendar,
                  size: 15,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          if (_showManufactureDetails) ...[
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
                key: row.mfdFieldKey,
                child: CustomTextField(
                  controller: row.mfdController,
                  hintText: 'MM/YYYY',
                  readOnly: true,
                  onTap: () => _pickBatchMonthYear(row: row, isExpiry: false),
                  suffixWidget: const Icon(
                    LucideIcons.calendar,
                    size: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: CustomTextField(
                controller: row.mfrBatchController,
                hintText: 'Enter batch no',
                readOnly: true,
              ),
            ),
          ],
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: CustomTextField(
              controller: row.quantityController,
              hintText: '0',
              textAlign: TextAlign.right,
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_showFocColumn) ...[
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: CustomTextField(
                controller: row.focController,
                hintText: '0',
                textAlign: TextAlign.right,
                readOnly: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
          if (widget.isOutAdjustment)
            SizedBox(
              width: 160,
              child: Builder(
                builder: (_) {
                  final qty = double.tryParse(row.quantityController.text) ?? 0;
                  final bal =
                      row.availableBalance ?? _batchBalanceById[row.id.trim()];
                  if (bal == null || qty <= 0) {
                    return const SizedBox.shrink();
                  }
                  if (qty <= bal) {
                    return Text(
                      'Balance: ${bal.toStringAsFixed(0)} pcs',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    );
                  }
                  return Text(
                    'Exceeds by ${(qty - bal).toStringAsFixed(2)} pcs',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removeRow(index),
            icon: const Icon(
              LucideIcons.trash2,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class BatchLookup {
  final Map<String, dynamic> data;
  BatchLookup(this.data);
  String get batchNo => data['batch_no']?.toString() ?? '-';
  String get batchReference => data['batch_reference']?.toString() ?? '-';
  double? get quantityAvailable =>
      double.tryParse(data['quantity_available']?.toString() ?? '0');
  double? get mrp => double.tryParse(data['mrp']?.toString() ?? '');
  DateTime? get mfdDate => data['mfd_date'] != null
      ? DateTime.tryParse(data['mfd_date'].toString())
      : null;
  DateTime? get expiryDate => data['expiry_date'] != null
      ? DateTime.tryParse(data['expiry_date'].toString())
      : null;
}

class BinLookup {
  final String id;
  final String code;
  const BinLookup({required this.id, required this.code});

  factory BinLookup.fromMap(Map<String, String> row) {
    return BinLookup(
      id: (row['id'] ?? '').trim(),
      code: (row['bin_code'] ?? '').trim(),
    );
  }
}

final _adjBinLookupProvider = FutureProvider.family<List<BinLookup>, String>((
  ref,
  warehouseId,
) async {
  if (warehouseId.trim().isEmpty) return const <BinLookup>[];
  final repo = ref.read(adjustmentsRepositoryProvider);
  final rows = await repo.getBinOptions(warehouseId);
  return rows
      .map(BinLookup.fromMap)
      .where((row) => row.id.isNotEmpty && row.code.isNotEmpty)
      .toList(growable: false);
});
