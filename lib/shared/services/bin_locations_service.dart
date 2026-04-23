import 'package:zerpai_erp/core/services/api_client.dart';

class ZoneLevelRecord {
  final int level;
  final String location;
  final String delimiter;
  final String aliasName;
  final int total;

  const ZoneLevelRecord({
    required this.level,
    required this.location,
    required this.delimiter,
    required this.aliasName,
    required this.total,
  });

  factory ZoneLevelRecord.fromJson(Map<String, dynamic> json) =>
      ZoneLevelRecord(
        level: int.tryParse((json['level'] ?? 1).toString()) ?? 1,
        location: (json['location'] ?? '').toString(),
        delimiter: (json['delimiter'] ?? '').toString(),
        aliasName: (json['alias_name'] ?? '').toString(),
        total: int.tryParse((json['total'] ?? 0).toString()) ?? 0,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'level': level,
    'location': location,
    'delimiter': delimiter,
    'alias_name': aliasName,
    'total': total,
  };
}

class ZoneRecord {
  final String id;
  final String branchId;
  final String branchName;
  final String zoneName;
  final String status;
  final String structureLayout;
  final int totalBins;
  final List<ZoneLevelRecord> levels;

  const ZoneRecord({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.zoneName,
    required this.status,
    required this.structureLayout,
    required this.totalBins,
    required this.levels,
  });

  factory ZoneRecord.fromJson(Map<String, dynamic> json) => ZoneRecord(
    id: (json['id'] ?? '').toString(),
    branchId: (json['branch_id'] ?? '').toString(),
    branchName: (json['branch_name'] ?? '').toString(),
    zoneName: (json['zone_name'] ?? '').toString(),
    status: (json['status'] ?? 'Active').toString(),
    structureLayout: (json['structure_layout'] ?? '').toString(),
    totalBins: int.tryParse((json['total_bins'] ?? 0).toString()) ?? 0,
    levels: ((json['levels'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) => ZoneLevelRecord.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(),
  );
}

class BinRecord {
  final String id;
  final String zoneId;
  final String name;
  final String description;
  final String status;
  final double stockOnHand;

  const BinRecord({
    required this.id,
    required this.zoneId,
    required this.name,
    required this.description,
    required this.status,
    required this.stockOnHand,
  });

  factory BinRecord.fromJson(Map<String, dynamic> json) => BinRecord(
    id: (json['id'] ?? '').toString(),
    zoneId: (json['zone_id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    status: (json['status'] ?? 'Active').toString(),
    stockOnHand:
        double.tryParse((json['stock_on_hand'] ?? '0').toString()) ?? 0,
  );
}

class ZoneBinsPageResult {
  final ZoneRecord zone;
  final List<BinRecord> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const ZoneBinsPageResult({
    required this.zone,
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory ZoneBinsPageResult.fromJson(Map<String, dynamic> json) =>
      ZoneBinsPageResult(
        zone: ZoneRecord.fromJson(
          Map<String, dynamic>.from(json['zone'] as Map),
        ),
        items: ((json['items'] as List?) ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => BinRecord.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        totalCount: int.tryParse((json['total_count'] ?? 0).toString()) ?? 0,
        page: int.tryParse((json['page'] ?? 1).toString()) ?? 1,
        pageSize: int.tryParse((json['page_size'] ?? 100).toString()) ?? 100,
      );
}

class BranchZoneBinsSummary {
  final int zoneCount;
  final int binCount;

  const BranchZoneBinsSummary({
    required this.zoneCount,
    required this.binCount,
  });

  bool get isEnabled => zoneCount > 0;

  String get label {
    if (zoneCount <= 0) {
      return '—';
    }
    final String zonesLabel = zoneCount == 1 ? 'Zone' : 'Zones';
    final String binsLabel = binCount == 1 ? 'Bin' : 'Bins';
    return '$zoneCount $zonesLabel / $binCount $binsLabel';
  }
}

class BinLocationsService {
  BinLocationsService._();

  static final BinLocationsService instance = BinLocationsService._();
  final ApiClient _apiClient = ApiClient();

  Future<List<ZoneRecord>> ensureDefaultZones({
    required String orgId,
    required String branchId,
    required String branchName,
  }) async {
    final response = await _apiClient.post(
      '/zones/ensure-defaults',
      data: <String, dynamic>{
        'org_id': orgId,
        'branch_id': branchId,
        'branch_name': branchName,
      },
    );
    final List<dynamic> raw = response.data is List
        ? response.data as List<dynamic>
        : <dynamic>[];
    return raw
        .whereType<Map>()
        .map((item) => ZoneRecord.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ZoneRecord>> getZones({
    required String orgId,
    required String branchId,
  }) async {
    final response = await _apiClient.get(
      '/zones',
      queryParameters: <String, dynamic>{
        'org_id': orgId,
        'branch_id': branchId,
      },
      useCache: false,
    );
    final List<dynamic> raw = response.data is List
        ? response.data as List<dynamic>
        : <dynamic>[];
    return raw
        .whereType<Map>()
        .map((item) => ZoneRecord.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ZoneRecord> createZone({
    required String orgId,
    required String branchId,
    required String branchName,
    required String zoneName,
    required List<ZoneLevelRecord> levels,
  }) async {
    final response = await _apiClient.post(
      '/zones',
      data: <String, dynamic>{
        'org_id': orgId,
        'branch_id': branchId,
        'branch_name': branchName,
        'zone_name': zoneName,
        'levels': levels.map((level) => level.toJson()).toList(),
      },
    );
    return ZoneRecord.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> disableBinLocations({
    required String orgId,
    required String branchId,
  }) async {
    await _apiClient.post(
      '/zones/disable',
      data: <String, dynamic>{'org_id': orgId, 'branch_id': branchId},
    );
  }

  Future<Map<String, int>> getZoneCounts({
    required String orgId,
    required Iterable<String> branchIds,
  }) async {
    final List<String> ids = branchIds
        .where((id) => id.trim().isNotEmpty)
        .toList();
    if (ids.isEmpty) {
      return <String, int>{};
    }
    final response = await _apiClient.get(
      '/zones/counts',
      queryParameters: <String, dynamic>{
        'org_id': orgId,
        'branch_ids': ids.join(','),
      },
      useCache: false,
    );
    final Map<String, dynamic> raw = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return raw.map(
      (key, value) => MapEntry(key, int.tryParse(value.toString()) ?? 0),
    );
  }

  Future<Map<String, BranchZoneBinsSummary>> getBranchZoneBinsSummaries({
    required String orgId,
    required Iterable<String> branchIds,
  }) async {
    final List<String> ids = branchIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) {
      return <String, BranchZoneBinsSummary>{};
    }

    final results = await Future.wait(
      ids.map((branchId) async {
        final zones = await getZones(orgId: orgId, branchId: branchId);
        final int binCount = zones.fold<int>(
          0,
          (total, zone) => total + zone.totalBins,
        );
        return MapEntry(
          branchId,
          BranchZoneBinsSummary(zoneCount: zones.length, binCount: binCount),
        );
      }),
    );

    return Map<String, BranchZoneBinsSummary>.fromEntries(results);
  }

  Future<ZoneBinsPageResult> getBins({
    required String orgId,
    required String branchId,
    required String zoneId,
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await _apiClient.get(
      '/zones/$zoneId/bins',
      queryParameters: <String, dynamic>{
        'org_id': orgId,
        'branch_id': branchId,
        'page': page,
        'page_size': pageSize,
      },
      useCache: false,
    );
    return ZoneBinsPageResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<BinRecord> createBin({
    required String zoneId,
    required String orgId,
    required String branchId,
    required String name,
    String description = '',
  }) async {
    final response = await _apiClient.post(
      '/zones/$zoneId/bins',
      data: <String, dynamic>{
        'org_id': orgId,
        'branch_id': branchId,
        'name': name,
        'description': description,
      },
    );
    return BinRecord.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<BinRecord> updateBin({
    required String binId,
    required String orgId,
    required String branchId,
    String? name,
    String? description,
    String? status,
  }) async {
    final response = await _apiClient.put(
      '/zones/bins/$binId',
      data: <String, dynamic>{
        'org_id': orgId,
        'branch_id': branchId,
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
      },
    );
    return BinRecord.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteBin({
    required String binId,
    required String orgId,
    required String branchId,
  }) async {
    await _apiClient.delete(
      '/zones/bins/$binId',
      queryParameters: <String, dynamic>{
        'org_id': orgId,
        'branch_id': branchId,
      },
    );
  }

  Future<void> bulkAction({
    required String orgId,
    required String branchId,
    required List<String> binIds,
    required String action,
  }) async {
    await _apiClient.post(
      '/zones/bins/bulk-action',
      data: <String, dynamic>{
        'org_id': orgId,
        'branch_id': branchId,
        'bin_ids': binIds,
        'action': action,
      },
    );
  }

  Future<void> bulkZoneAction({
    required String orgId,
    required String branchId,
    required List<String> zoneIds,
    required String action,
  }) async {
    await _apiClient.post(
      '/zones/bulk-action',
      data: <String, dynamic>{
        'org_id': orgId,
        'branch_id': branchId,
        'zone_ids': zoneIds,
        'action': action,
      },
    );
  }
}
