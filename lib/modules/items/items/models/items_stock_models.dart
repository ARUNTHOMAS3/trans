// lib/modules/items/items/models/items_stock_models.dart

class WarehouseStockRow {
  final String id;
  final String name;
  final bool isPrimary;
  final double openingStock;
  final double openingStockValue;
  final StockNumbers accounting;
  final StockNumbers physical;

  WarehouseStockRow({
    required this.id,
    required this.name,
    required this.accounting,
    required this.physical,
    this.isPrimary = false,
    this.openingStock = 0,
    this.openingStockValue = 0,
  });

  factory WarehouseStockRow.fromJson(Map<String, dynamic> json) =>
      WarehouseStockRow(
        id: (json['warehouse_id'] ?? json['id'] ?? '').toString(),
        name: json['name'],
        isPrimary: json['isPrimary'] ?? false,
        openingStock:
            (json['opening_stock'] as num?)?.toDouble() ??
            (json['openingStock'] as num?)?.toDouble() ??
            0,
        openingStockValue:
            (json['opening_stock_value'] as num?)?.toDouble() ??
            (json['openingStockValue'] as num?)?.toDouble() ??
            0,
        accounting: StockNumbers.fromJson(json['accounting']),
        physical: StockNumbers.fromJson(json['physical']),
      );

  Map<String, dynamic> toJson() => {
    'warehouse_id': id,
    'name': name,
    'isPrimary': isPrimary,
    'opening_stock': openingStock,
    'opening_stock_value': openingStockValue,
    'accounting': accounting.toJson(),
    'physical': physical.toJson(),
  };

  double get variance => physical.onHand - accounting.onHand;

  bool get hasVariance => variance.abs() > 0.0001;
}

class StockNumbers {
  final double onHand;
  final double committed;

  const StockNumbers({required this.onHand, required this.committed});

  double get available => (onHand - committed).clamp(0, double.infinity);

  bool get isOverCommitted => committed > onHand;

  double get shortfall => (committed - onHand).clamp(0, double.infinity);

  factory StockNumbers.fromJson(Map<String, dynamic> json) => StockNumbers(
    onHand: (json['onHand'] as num).toDouble(),
    committed: (json['committed'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {'onHand': onHand, 'committed': committed};
}

enum OpeningStockMode { none, batches, serials }

class BatchData {
  final String batchReference;
  final String manufacturerBatch;
  final int unitPack;
  final String manufacturedDate;
  final String expiryDate;
  final int quantityIn;
  final int quantityAvailable;

  BatchData({
    required this.batchReference,
    required this.manufacturerBatch,
    required this.unitPack,
    required this.manufacturedDate,
    required this.expiryDate,
    required this.quantityIn,
    required this.quantityAvailable,
  });

  bool get isExpired {
    if (expiryDate.isEmpty) return false;
    try {
      final parts = expiryDate.split('-');
      if (parts.length != 3) return false;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final expiry = DateTime(year, month, day);
      return expiry.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  factory BatchData.fromJson(Map<String, dynamic> json) => BatchData(
    batchReference: json['batchReference'] ?? '',
    manufacturerBatch: json['manufacturerBatch'] ?? '',
    unitPack: json['unitPack'] ?? 0,
    manufacturedDate: json['manufacturedDate'] ?? '',
    expiryDate: json['expiryDate'] ?? '',
    quantityIn: json['quantityIn'] ?? 0,
    quantityAvailable: json['quantityAvailable'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'batchReference': batchReference,
    'manufacturerBatch': manufacturerBatch,
    'unitPack': unitPack,
    'manufacturedDate': manufacturedDate,
    'expiryDate': expiryDate,
    'quantityIn': quantityIn,
    'quantityAvailable': quantityAvailable,
  };
}

class SerialData {
  final String serialNumber;
  final String warehouseName;
  final bool isAvailable;

  SerialData({
    required this.serialNumber,
    required this.warehouseName,
    required this.isAvailable,
  });

  factory SerialData.fromJson(Map<String, dynamic> json) => SerialData(
    serialNumber: json['serialNumber'] ?? '',
    warehouseName: json['warehouseName'] ?? '',
    isAvailable: json['isAvailable'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'serialNumber': serialNumber,
    'warehouseName': warehouseName,
    'isAvailable': isAvailable,
  };
}

class TransactionData {
  final String date;
  final String documentNumber;
  final String customerName;
  final double quantitySold;
  final double price;
  final double total;
  final String status;
  final String documentType;
  final String? reference;

  TransactionData({
    required this.date,
    required this.documentNumber,
    required this.customerName,
    required this.quantitySold,
    required this.price,
    required this.total,
    required this.status,
    required this.documentType,
    this.reference,
  });

  factory TransactionData.fromJson(Map<String, dynamic> json) =>
      TransactionData(
        date: json['date'] ?? '',
        documentNumber: json['documentNumber'] ?? '',
        customerName: json['customerName'] ?? '',
        quantitySold: (json['quantitySold'] as num?)?.toDouble() ?? 0.0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] ?? '',
        documentType: json['documentType'] ?? json['type'] ?? '',
        reference: json['reference'],
      );

  Map<String, dynamic> toJson() => {
    'date': date,
    'documentNumber': documentNumber,
    'customerName': customerName,
    'quantitySold': quantitySold,
    'price': price,
    'total': total,
    'status': status,
    'documentType': documentType,
    'reference': reference,
  };
}

class ItemHistoryEntry {
  final String id;
  final String tableName;
  final String section;
  final String action;
  final String recordId;
  final String? recordPk;
  final String actorName;
  final String source;
  final String? requestId;
  final String? moduleName;
  final DateTime? createdAt;
  final List<String> changedColumns;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String summary;

  ItemHistoryEntry({
    required this.id,
    required this.tableName,
    required this.section,
    required this.action,
    required this.recordId,
    required this.actorName,
    required this.source,
    required this.summary,
    this.recordPk,
    this.requestId,
    this.moduleName,
    this.createdAt,
    this.changedColumns = const <String>[],
    this.oldValues,
    this.newValues,
  });

  factory ItemHistoryEntry.fromJson(Map<String, dynamic> json) {
    List<String> changedColumnsFrom(dynamic value) {
      if (value is List) {
        return value.map((entry) => entry.toString()).toList();
      }
      return const <String>[];
    }

    Map<String, dynamic>? mapFrom(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.map((key, entry) => MapEntry(key.toString(), entry));
      }
      return null;
    }

    return ItemHistoryEntry(
      id: (json['id'] ?? '').toString(),
      tableName: (json['table_name'] ?? '').toString(),
      section: (json['section'] ?? 'History').toString(),
      action: (json['action'] ?? '').toString(),
      recordId: (json['record_id'] ?? '').toString(),
      recordPk: json['record_pk']?.toString(),
      actorName: (json['actor_name'] ?? 'system').toString(),
      source: (json['source'] ?? 'system').toString(),
      requestId: json['request_id']?.toString(),
      moduleName: json['module_name']?.toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      changedColumns: changedColumnsFrom(json['changed_columns']),
      oldValues: mapFrom(json['old_values']),
      newValues: mapFrom(json['new_values']),
      summary: (json['summary'] ?? '').toString(),
    );
  }
}
