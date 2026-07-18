import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/stock_count_model.dart';

class StockCountsState {
  final List<StockCount> counts;
  final bool isLoading;
  final StockCountStatus? activeFilter;
  final String searchQuery;
  final String? assignedToFilter;
  final String? locationFilter;

  const StockCountsState({
    required this.counts,
    this.isLoading = false,
    this.activeFilter,
    this.searchQuery = '',
    this.assignedToFilter,
    this.locationFilter,
  });

  List<StockCount> get filteredCounts {
    var list = counts.where((c) => !c.isRecurring).toList();

    if (activeFilter != null) {
      list = list.where((c) => c.status == activeFilter).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((c) {
        return c.stockCountNum.toLowerCase().contains(q) ||
            c.assignedTo.toLowerCase().contains(q);
      }).toList();
    }

    if (assignedToFilter != null && assignedToFilter != 'None') {
      list = list.where((c) => c.assignedTo == assignedToFilter).toList();
    }

    final locFilter = locationFilter;
    if (locFilter != null &&
        locFilter != 'None' &&
        locFilter.trim().isNotEmpty) {
      final locs = locFilter.split(',').where((x) => x.isNotEmpty).toList();
      if (locs.isNotEmpty) {
        list = list.where((c) => locs.contains(c.location)).toList();
      }
    }

    return list;
  }

  StockCountsState copyWith({
    List<StockCount>? counts,
    bool? isLoading,
    StockCountStatus? activeFilter,
    bool clearFilter = false,
    String? searchQuery,
    String? assignedToFilter,
    bool clearAssignedToFilter = false,
    String? locationFilter,
    bool clearLocationFilter = false,
  }) {
    return StockCountsState(
      counts: counts ?? this.counts,
      isLoading: isLoading ?? this.isLoading,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      assignedToFilter: clearAssignedToFilter
          ? null
          : (assignedToFilter ?? this.assignedToFilter),
      locationFilter: clearLocationFilter
          ? null
          : (locationFilter ?? this.locationFilter),
    );
  }
}

class StockCountsNotifier extends StateNotifier<StockCountsState> {
  static const String _configBoxName = 'config';
  static const String _itemStateCachePrefix = 'stock_count_item_state_';

  StockCountsNotifier() : super(const StockCountsState(counts: [])) {
    fetchCounts();
  }

  Box? _getConfigBox() {
    try {
      return Hive.box(_configBoxName);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistItemState(
    String ownerId,
    List<Map<String, dynamic>> items,
  ) async {
    final box = _getConfigBox();
    if (box == null || ownerId.trim().isEmpty || items.isEmpty) return;

    final payload = items.map((item) {
      final batches = (item['batches'] as List? ?? const [])
          .map((batch) => Map<String, dynamic>.from(batch as Map))
          .toList();

      return <String, dynamic>{
        'product_id': item['product_id']?.toString(),
        'sku': item['sku']?.toString(),
        'name': item['name']?.toString(),
        'countedQty': item['countedQty'],
        'track_batches': item['track_batches'],
        'hasInvalidBatch': item['hasInvalidBatch'],
        'batches': batches,
      };
    }).toList();

    await box.put('$_itemStateCachePrefix$ownerId', payload);
  }

  List<Map<String, dynamic>> _readPersistedItemState(String ownerId) {
    final box = _getConfigBox();
    if (box == null || ownerId.trim().isEmpty) return const [];

    final raw = box.get('$_itemStateCachePrefix$ownerId');
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  void _mergeItemStateRows(
    List<Map<String, dynamic>> sourceRows,
    List<Map<String, dynamic>> items,
  ) {
    if (sourceRows.isEmpty || items.isEmpty) return;

    final persistedByProductId = <String, Map<String, dynamic>>{};
    final persistedBySku = <String, Map<String, dynamic>>{};
    final persistedByName = <String, Map<String, dynamic>>{};

    for (final row in sourceRows) {
      final productId = (row['product_id'] ?? '').toString().trim();
      final sku = (row['sku'] ?? '').toString().trim().toLowerCase();
      final name = (row['name'] ?? '').toString().trim().toLowerCase();

      if (productId.isNotEmpty) {
        persistedByProductId[productId] = row;
      }
      if (sku.isNotEmpty) {
        persistedBySku[sku] = row;
      }
      if (name.isNotEmpty) {
        persistedByName[name] = row;
      }
    }

    for (final item in items) {
      final productId = (item['product_id'] ?? '').toString().trim();
      final sku = (item['sku'] ?? '').toString().trim().toLowerCase();
      final name = (item['name'] ?? '').toString().trim().toLowerCase();

      final persistedRow =
          (productId.isNotEmpty ? persistedByProductId[productId] : null) ??
          (sku.isNotEmpty ? persistedBySku[sku] : null) ??
          (name.isNotEmpty ? persistedByName[name] : null);

      if (persistedRow == null) continue;

      item['countedQty'] = persistedRow['countedQty'];
      item['track_batches'] =
          persistedRow['track_batches'] ?? item['track_batches'];
      item['hasInvalidBatch'] =
          persistedRow['hasInvalidBatch'] ?? item['hasInvalidBatch'];
      item['batches'] =
          (persistedRow['batches'] as List? ?? const [])
              .whereType<Map>()
              .map((batch) => Map<String, dynamic>.from(batch))
              .toList();
    }
  }

  void _mergePersistedItemState(
    String ownerId,
    List<Map<String, dynamic>> items,
  ) {
    final persisted = _readPersistedItemState(ownerId);
    _mergeItemStateRows(persisted, items);
  }

  void _mergeInMemoryItemState(
    String ownerId,
    List<Map<String, dynamic>> items,
  ) {
    final existingCount = state.counts.cast<StockCount?>().firstWhere(
      (count) => count?.id == ownerId,
      orElse: () => null,
    );
    if (existingCount == null || existingCount.items.isEmpty) return;

    final sourceRows = existingCount.items
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    _mergeItemStateRows(sourceRows, items);
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadItemDetails(
    SupabaseClient supabase,
    List<String> ownerIds,
    Map<String, String?> warehouseIdByOwnerId,
  ) async {
    final result = <String, List<Map<String, dynamic>>>{};
    if (ownerIds.isEmpty) return result;

    final itemRows = await supabase
        .from('stock_count_items')
        .select('stock_count_id, product_id, rate, sku')
        .inFilter('stock_count_id', ownerIds);

    final groupedRows = <String, List<Map<String, dynamic>>>{};
    final productIds = <String>{};

    for (final raw in itemRows as List<dynamic>) {
      final row = Map<String, dynamic>.from(raw as Map);
      final ownerId = row['stock_count_id'] as String?;
      if (ownerId == null || ownerId.trim().isEmpty) continue;
      groupedRows.putIfAbsent(ownerId, () => <Map<String, dynamic>>[]).add(row);
      final productId = row['product_id'] as String?;
      if (productId != null && productId.trim().isNotEmpty) {
        productIds.add(productId);
      }
    }

    final prodMap = <String, dynamic>{};
    final stockMapByWarehouseProduct = <String, double>{};
    final stockMapByProduct = <String, double>{};

    if (productIds.isNotEmpty) {
      final productsInfo = await supabase
          .from('products')
          .select('id, product_name, sku, track_bin_location, units(unit_name)')
          .inFilter('id', productIds.toList());

      for (final raw in productsInfo as List<dynamic>) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String?;
        if (id != null) {
          prodMap[id] = row;
        }
      }

      final stockData = await supabase
          .from('v_physical_stock')
          .select('product_id, warehouse_id, stock_on_hand')
          .inFilter('product_id', productIds.toList());

      for (final raw in stockData as List<dynamic>) {
        final row = raw as Map<String, dynamic>;
        final pid = row['product_id'] as String?;
        final warehouseId = row['warehouse_id'] as String?;
        final qty =
            double.tryParse(row['stock_on_hand']?.toString() ?? '') ?? 0.0;
        if (pid != null) {
          stockMapByProduct[pid] = (stockMapByProduct[pid] ?? 0.0) + qty;
          final stockKey = warehouseId == null || warehouseId.trim().isEmpty
              ? null
              : '$warehouseId::$pid';
          if (stockKey != null) {
            stockMapByWarehouseProduct[stockKey] =
                (stockMapByWarehouseProduct[stockKey] ?? 0.0) + qty;
          }
        }
      }
    }

    for (final entry in groupedRows.entries) {
      final itemsList = <Map<String, dynamic>>[];
      final warehouseId = warehouseIdByOwnerId[entry.key]?.trim();
      for (final itemRow in entry.value) {
        final pid = itemRow['product_id'] as String?;
        if (pid == null) continue;
        final prod = prodMap[pid] as Map<String, dynamic>?;
        final unit = prod?['units'] as Map<String, dynamic>?;
        final stockKey =
            warehouseId == null || warehouseId.isEmpty ? null : '$warehouseId::$pid';
        final stockVal = stockKey != null
            ? (stockMapByWarehouseProduct[stockKey] ?? 0.0)
            : (stockMapByProduct[pid] ?? 0.0);

        itemsList.add({
          'product_id': pid,
          'sku': itemRow['sku'] ?? prod?['sku'] ?? 'N/A',
          'rate': itemRow['rate'] != null
              ? double.tryParse(itemRow['rate'].toString()) ?? 0.0
              : 0.0,
          'name': prod?['product_name'] ?? 'Unknown Item',
          'unit': unit?['unit_name'] ?? 'pcs',
          'stock': stockVal.toStringAsFixed(2),
          'systemQty': stockVal.toInt(),
          'countedQty': null,
          'track_bin_location': prod?['track_bin_location'] ?? false,
          'batches': <Map<String, dynamic>>[],
        });
      }
      _mergeInMemoryItemState(entry.key, itemsList);
      _mergePersistedItemState(entry.key, itemsList);
      result[entry.key] = itemsList;
    }

    return result;
  }

  List<DateTime> _calculateDueDates({
    required DateTime startDate,
    required String? frequency,
    required int frequencyValue,
    required String? scheduleType,
    required List<dynamic>? customDates,
    DateTime? expiryDate,
    required DateTime now,
  }) {
    final List<DateTime> dueDates = [];
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime(now.year, now.month, now.day);
    final endDate = expiryDate == null
        ? today
        : (expiryDate.isBefore(today) ? expiryDate : today);
    final interval = frequencyValue > 0 ? frequencyValue : 1;

    if (start.isAfter(endDate)) return dueDates;

    if (scheduleType?.toLowerCase() == 'custom') {
      if (customDates != null) {
        for (final d in customDates) {
          final parsed = DateTime.tryParse(d.toString());
          if (parsed != null) {
            final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
            if (!dateOnly.isBefore(start) && !dateOnly.isAfter(endDate)) {
              dueDates.add(dateOnly);
            }
          }
        }
      }
      return dueDates;
    }

    final freq = frequency?.toLowerCase() ?? '';
    if (freq.contains('day')) {
      var current = start;
      while (!current.isAfter(endDate)) {
        dueDates.add(current);
        current = current.add(Duration(days: interval));
      }
    } else if (freq.contains('week')) {
      var current = start;
      while (!current.isAfter(endDate)) {
        dueDates.add(current);
        current = current.add(Duration(days: 7 * interval));
      }
    } else if (freq.contains('month')) {
      var current = start;
      while (!current.isAfter(endDate)) {
        dueDates.add(current);
        current = DateTime(current.year, current.month + interval, current.day);
      }
    } else if (freq.contains('year')) {
      var current = start;
      while (!current.isAfter(endDate)) {
        dueDates.add(current);
        current = DateTime(current.year + interval, current.month, current.day);
      }
    } else {
      dueDates.add(start);
    }

    return dueDates;
  }

  DateTime? _parseScheduleExpiryDate(String? rawValue) {
    final raw = rawValue?.trim() ?? '';
    if (raw.isEmpty || raw.toLowerCase() == 'never expires') {
      return null;
    }

    final normalized = raw.startsWith('On ') ? raw.substring(3).trim() : raw;
    final dashMatch = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(
      normalized,
    );
    if (dashMatch != null) {
      final day = int.tryParse(dashMatch.group(1) ?? '');
      final month = int.tryParse(dashMatch.group(2) ?? '');
      final year = int.tryParse(dashMatch.group(3) ?? '');
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    final textMatch = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})$',
    ).firstMatch(normalized);
    if (textMatch == null) return null;

    const months = <String, int>{
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    final day = int.tryParse(textMatch.group(1) ?? '');
    final month = months[textMatch.group(2)];
    final year = int.tryParse(textMatch.group(3) ?? '');
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _hasRecurringExpired(String? scheduleExpiry, DateTime now) {
    final expiryDate = _parseScheduleExpiryDate(scheduleExpiry);
    if (expiryDate == null) return false;
    return _dateOnly(now).isAfter(_dateOnly(expiryDate));
  }

  Future<void> fetchCounts() async {
    try {
      final supabase = Supabase.instance.client;

      final warehousesRes = await supabase.from('warehouses').select('id, name');
      final warehouseNameById = <String, String>{};
      for (final raw in warehousesRes as List<dynamic>) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String?;
        final name = row['name'] as String?;
        if (id != null && id.trim().isNotEmpty && name != null) {
          warehouseNameById[id] = name;
        }
      }

      final usersRes = await supabase
          .from('users')
          .select('id, full_name, email');
      final userNameById = <String, String>{};
      for (final raw in usersRes as List<dynamic>) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String?;
        if (id == null || id.trim().isEmpty) continue;
        final fullName = (row['full_name'] as String? ?? '').trim();
        final email = (row['email'] as String? ?? '').trim();
        final label = fullName.isNotEmpty ? fullName : email;
        if (label.isNotEmpty) {
          userNameById[id] = label;
        }
      }

      final manualRows = List<dynamic>.from(await supabase.from('inventory_stock_count').select('*'));
      final recurringRows = List<dynamic>.from(
          await supabase.from('inventory_recurring_stock_count').select('*'));

      final ownerIds = <String>{};
      for (final raw in manualRows) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String?;
        if (id != null && id.trim().isNotEmpty) {
          ownerIds.add(id);
        }
      }
      for (final raw in recurringRows) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String?;
        if (id != null && id.trim().isNotEmpty) {
          ownerIds.add(id);
        }
      }

      final warehouseIdByOwnerId = <String, String?>{};
      for (final raw in manualRows) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String?;
        if (id == null || id.trim().isEmpty) continue;
        warehouseIdByOwnerId[id] =
            row['warehouse_id'] as String? ?? row['warehouse'] as String?;
      }
      for (final raw in recurringRows) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String?;
        if (id == null || id.trim().isEmpty) continue;
        warehouseIdByOwnerId[id] = row['warehouse'] as String?;
      }

      final itemsByOwnerId = await _loadItemDetails(
        supabase,
        ownerIds.toList(),
        warehouseIdByOwnerId,
      );

      // Auto-generate missing regular stock counts from recurring profiles
      final List<Map<String, dynamic>> newManualRows = [];
      final todayNow = DateTime.now();
      final recurringStatusUpdates = <Map<String, dynamic>>[];

      for (final rawRec in recurringRows) {
        final recRow = rawRec as Map<String, dynamic>;
        final isExpired = _hasRecurringExpired(
          recRow['schedule_expires_after'] as String?,
          todayNow,
        );
        final isActive = (recRow['is_active'] as bool? ?? true) && !isExpired;
        if (isExpired) {
          recRow['status'] = 'Expired';
          recRow['is_active'] = false;
          final recurringId = recRow['id'] as String?;
          if (recurringId != null && recurringId.trim().isNotEmpty) {
            recurringStatusUpdates.add({
              'id': recurringId,
              'status': 'Expired',
              'is_active': false,
            });
          }
        }
        if (!isActive) continue;

        final startDateStr = recRow['schedule_starts_on']?.toString();
        if (startDateStr == null || startDateStr.trim().isEmpty) continue;
        final startDate = DateTime.tryParse(startDateStr);
        if (startDate == null) continue;

        final frequency = recRow['frequency'] as String?;
        final frequencyValue =
            int.tryParse(recRow['frequency_value']?.toString() ?? '') ?? 1;
        final scheduleType = recRow['schedule_type'] as String?;
        final customDates = recRow['custom_schedule_dates'] as List<dynamic>?;
        final expiryDate = _parseScheduleExpiryDate(
          recRow['schedule_expires_after'] as String?,
        );
        final recurringProfileName = recRow['stock_count_number'] as String?;
        if (recurringProfileName == null || recurringProfileName.trim().isEmpty) continue;

        final dueDates = _calculateDueDates(
          startDate: startDate,
          frequency: frequency,
          frequencyValue: frequencyValue,
          scheduleType: scheduleType,
          customDates: customDates,
          expiryDate: expiryDate,
          now: todayNow,
        );

        for (final dueDate in dueDates) {
          final dueDateStr = DateFormat('yyyy-MM-dd').format(dueDate);
          // Check if there is already a manual stock count for this recurring profile on this date
          final exists = manualRows.any((m) {
            final mRow = m as Map<String, dynamic>;
            final startOn = mRow['schedule_starts_on']?.toString();
            final parsedStart = startOn != null ? DateTime.tryParse(startOn) : null;
            final startOnStr = parsedStart != null ? DateFormat('yyyy-MM-dd').format(parsedStart) : null;
            return mRow['stock_count_name'] == recurringProfileName &&
                startOnStr == dueDateStr;
          });

          if (!exists) {
            // Generate standard stock count record in Supabase
            final newId = const Uuid().v4();
            final payload = <String, dynamic>{
              'id': newId,
              'stock_count_number': '$recurringProfileName-$dueDateStr',
              'stock_count_name': recurringProfileName,
              'description': recRow['description'],
              'warehouse': recRow['warehouse'],
              'warehouse_id': recRow['warehouse'],
              'assign_to': recRow['assign_to'],
              'schedule_type': 'Manual',
              'frequency': null,
              'schedule_starts_on': dueDateStr,
              'generate_count_at': recRow['generate_count_at'],
              'execution_time': recRow['execution_time'],
              'is_schedule_enabled': false,
              'entity_id': recRow['entity_id'],
              'status': 'Yet to Start',
            };

            try {
              await supabase.from('inventory_stock_count').insert(payload);
              
              // Copy items associated with this recurring profile to stock_count_items
              final profileItems = itemsByOwnerId[recRow['id']] ?? [];
              if (profileItems.isNotEmpty) {
                final itemRowsToInsert = profileItems.map((item) {
                  return {
                    'stock_count_id': newId,
                    'product_id': item['product_id'],
                    'sku': item['sku'] ?? 'N/A',
                    'rate': item['rate'] ?? 0.0,
                  };
                }).toList();
                await supabase.from('stock_count_items').insert(itemRowsToInsert);
                itemsByOwnerId[newId] = profileItems;
              }
              
              newManualRows.add(payload);
            } catch (err) {
              print('Error auto-generating scheduled stock count: $err');
            }
          }
        }
      }

      for (final update in recurringStatusUpdates) {
        try {
          await supabase
              .from('inventory_recurring_stock_count')
              .update({
                'status': update['status'],
                'is_active': update['is_active'],
              })
              .eq('id', update['id']);
        } catch (err) {
          print('Error updating recurring stock count expiry status: $err');
        }
      }

      if (newManualRows.isNotEmpty) {
        manualRows.addAll(newManualRows);
      }

      final dbCounts = <StockCount>[];

      for (final raw in manualRows) {
        final row = raw as Map<String, dynamic>;
        if (row['is_schedule_enabled'] == true) {
          continue;
        }
        final id = row['id'] as String?;
        if (id == null || id.trim().isEmpty) continue;

        final warehouseId =
            row['warehouse_id'] as String? ?? row['warehouse'] as String?;
        final locationName =
            warehouseNameById[warehouseId] ?? 'Primary Warehouse';
        final assignToId = row['assign_to'] as String?;
        final assignedToName =
            assignToId == null ? null : userNameById[assignToId];

        dbCounts.add(
          StockCount(
            id: id,
            stockCountNum: row['stock_count_number'] as String? ?? id,
            recurringName: row['stock_count_name'] as String?,
            description: row['description'] as String?,
            location: locationName,
            warehouseId: warehouseId,
            assignedTo: assignedToName ?? assignToId ?? '',
            status: StockCountStatus.fromLabel(
              row['status']?.toString() ?? 'Yet to Start',
            ),
            countDate:
                DateTime.tryParse(row['schedule_starts_on']?.toString() ?? '') ??
                DateTime.now(),
            isRecurring: false,
            scheduleType: row['schedule_type'] as String?,
            frequency: row['frequency'] as String?,
            scheduleStartDate:
                DateTime.tryParse(row['schedule_starts_on']?.toString() ?? ''),
            scheduleExpiry: row['schedule_expires_after'] as String?,
            countGenerationTime: row['generate_count_at'] as String?,
            generateCountOn: row['generate_count_on'],
            nextCountDate: null,
            isActive: true,
            totalItems: itemsByOwnerId[id]?.length ?? 0,
            items: itemsByOwnerId[id] ?? const [],
          ),
        );
      }

      for (final raw in recurringRows) {
        final row = raw;
        final id = row['id'] as String?;
        if (id == null || id.trim().isEmpty) continue;

        final warehouseId = row['warehouse'] as String?;
        final locationName =
            warehouseNameById[warehouseId] ?? 'Primary Warehouse';
        final assignToId = row['assign_to'] as String?;
        final assignedToName =
            assignToId == null ? null : userNameById[assignToId];

        dbCounts.add(
          StockCount(
            id: id,
            stockCountNum: row['stock_count_number'] as String? ?? id,
            recurringName: row['stock_count_number'] as String?,
            description: row['description'] as String?,
            location: locationName,
            warehouseId: warehouseId,
            assignedTo: assignedToName ?? assignToId ?? '',
            status: StockCountStatus.fromLabel(
              row['status']?.toString() ?? 'Yet to Start',
            ),
            countDate:
                DateTime.tryParse(row['schedule_starts_on']?.toString() ?? '') ??
                DateTime.now(),
            isRecurring: true,
            scheduleType: row['schedule_type'] as String?,
            frequency: row['frequency'] as String?,
            scheduleStartDate:
                DateTime.tryParse(row['schedule_starts_on']?.toString() ?? ''),
            scheduleExpiry: row['schedule_expires_after'] as String?,
            countGenerationTime: row['generate_count_at'] as String?,
            generateCountOn: row['generate_count_on'],
            nextCountDate: null,
            isActive: row['is_active'] as bool? ?? true,
            totalItems: itemsByOwnerId[id]?.length ?? 0,
            items: itemsByOwnerId[id] ?? const [],
          ),
        );
      }

      for (final count in dbCounts) {
        _mergeInMemoryItemState(count.id, count.items);
        _mergePersistedItemState(count.id, count.items);
      }

      state = state.copyWith(counts: dbCounts);
    } catch (e, st) {
      print('Error fetching counts from Supabase: $e\n$st');
    }
  }

  void addCount(StockCount count) {
    state = state.copyWith(counts: [count, ...state.counts]);
  }

  Future<void> updateCount(StockCount updated) async {
    state = state.copyWith(
      counts: state.counts
          .map((c) => c.id == updated.id ? updated : c)
          .toList(),
    );
    try {
      await _persistItemState(updated.id, updated.items);

      final supabase = Supabase.instance.client;
      String statusStr = 'Yet to Start';
      switch (updated.status) {
        case StockCountStatus.yetToStart:
          statusStr = 'Yet to Start';
          break;
        case StockCountStatus.inProgress:
          statusStr = 'Counting In Progress';
          break;
        case StockCountStatus.pendingApproval:
          statusStr = 'Pending Approval';
          break;
        case StockCountStatus.approvalInProgress:
          statusStr = 'Approval In Progress';
          break;
        case StockCountStatus.completed:
          statusStr = 'Completed';
          break;
        case StockCountStatus.cancelled:
          statusStr = 'Cancelled';
          break;
        case StockCountStatus.expired:
          statusStr = 'Expired';
          break;
      }

      final table = updated.isRecurring
          ? 'inventory_recurring_stock_count'
          : 'inventory_stock_count';
      await supabase.from(table).update({'status': statusStr}).eq('id', updated.id);
    } catch (e) {
      print('Error updating stock count status in Supabase: $e');
    }
  }

  void deleteCount(String id) {
    state = state.copyWith(
      counts: state.counts.where((c) => c.id != id).toList(),
    );
  }

  void setFilter(StockCountStatus? filter) {
    if (filter == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: filter);
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setAssignedToFilter(String? value) {
    if (value == null || value == 'None') {
      state = state.copyWith(clearAssignedToFilter: true);
    } else {
      state = state.copyWith(assignedToFilter: value);
    }
  }

  void setLocationFilter(String? value) {
    if (value == null || value == 'None') {
      state = state.copyWith(clearLocationFilter: true);
    } else {
      state = state.copyWith(locationFilter: value);
    }
  }
}

final stockCountsProvider =
    StateNotifierProvider<StockCountsNotifier, StockCountsState>((ref) {
      return StockCountsNotifier();
    });
