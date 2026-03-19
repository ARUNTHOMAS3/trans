import 'package:flutter_test/flutter_test.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';

void main() {
  group('StockNumbers', () {
    test('available is clamped at zero when committed exceeds on hand', () {
      const numbers = StockNumbers(onHand: 5, committed: 8);

      expect(numbers.available, 0);
      expect(numbers.isOverCommitted, isTrue);
      expect(numbers.shortfall, 3);
    });

    test('available stays positive when stock is sufficient', () {
      const numbers = StockNumbers(onHand: 12, committed: 4);

      expect(numbers.available, 8);
      expect(numbers.isOverCommitted, isFalse);
      expect(numbers.shortfall, 0);
    });
  });

  group('WarehouseStockRow', () {
    test('parses warehouse stock payload and computes variance', () {
      final row = WarehouseStockRow.fromJson(<String, dynamic>{
        'warehouse_id': 'wh-1',
        'name': 'Central Logistics Hub',
        'opening_stock': 10,
        'opening_stock_value': 1250,
        'accounting': <String, dynamic>{'onHand': 10, 'committed': 2},
        'physical': <String, dynamic>{'onHand': 8, 'committed': 1},
      });

      expect(row.id, 'wh-1');
      expect(row.name, 'Central Logistics Hub');
      expect(row.openingStock, 10);
      expect(row.openingStockValue, 1250);
      expect(row.accounting.available, 8);
      expect(row.physical.available, 7);
      expect(row.variance, -2);
      expect(row.hasVariance, isTrue);
    });
  });

  group('ItemHistoryEntry', () {
    test('parses audit payload into a readable history model', () {
      final entry = ItemHistoryEntry.fromJson(<String, dynamic>{
        'id': 'audit-1',
        'table_name': 'products',
        'section': 'Products',
        'action': 'UPDATE',
        'record_id': 'product-1',
        'actor_name': 'system',
        'source': 'system',
        'summary': 'Storage changed from Store below 25°C to Store below 30°C',
        'created_at': '2026-03-18T16:53:00.000Z',
        'changed_columns': <String>['storage_id', 'buying_rule_id'],
        'old_values': <String, dynamic>{'storage_id': 'old-storage'},
        'new_values': <String, dynamic>{'storage_id': 'new-storage'},
      });

      expect(entry.id, 'audit-1');
      expect(entry.tableName, 'products');
      expect(entry.section, 'Products');
      expect(entry.action, 'UPDATE');
      expect(entry.recordId, 'product-1');
      expect(entry.summary, contains('Storage changed'));
      expect(entry.createdAt, isNotNull);
      expect(entry.changedColumns, <String>['storage_id', 'buying_rule_id']);
      expect(entry.oldValues?['storage_id'], 'old-storage');
      expect(entry.newValues?['storage_id'], 'new-storage');
    });
  });
}
