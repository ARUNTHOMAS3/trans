import 'package:flutter_test/flutter_test.dart';
import 'package:zerpai_erp/modules/items/items/models/item_composition_model.dart';

void main() {
  group('ItemComposition.fromJson', () {
    group('flat keys', () {
      test('parses content_id and strength_id from top-level fields', () {
        final comp = ItemComposition.fromJson({
          'content_id': 'cnt-1',
          'strength_id': 'str-1',
          'content_name': 'Paracetamol',
          'strength_name': '500mg',
        });

        expect(comp.contentId, 'cnt-1');
        expect(comp.strengthId, 'str-1');
        expect(comp.contentName, 'Paracetamol');
        expect(comp.strengthName, '500mg');
      });

      test('falls back to camelCase keys contentId / strengthId', () {
        final comp = ItemComposition.fromJson({
          'contentId': 'cnt-2',
          'strengthId': 'str-2',
          'contentName': 'Ibuprofen',
          'strengthName': '400mg',
        });

        expect(comp.contentId, 'cnt-2');
        expect(comp.strengthId, 'str-2');
        expect(comp.contentName, 'Ibuprofen');
        expect(comp.strengthName, '400mg');
      });

      test('handles all-null payload gracefully', () {
        final comp = ItemComposition.fromJson({});

        expect(comp.contentId, isNull);
        expect(comp.strengthId, isNull);
        expect(comp.contentName, isNull);
        expect(comp.strengthName, isNull);
      });
    });

    group('nested content Map', () {
      test('reads content_name and id from nested content Map', () {
        final comp = ItemComposition.fromJson({
          'content': {'id': 'cnt-3', 'content_name': 'Amoxicillin'},
          'strength': {'id': 'str-3', 'strength_name': '250mg'},
        });

        expect(comp.contentId, 'cnt-3');
        expect(comp.strengthId, 'str-3');
        expect(comp.contentName, 'Amoxicillin');
        expect(comp.strengthName, '250mg');
      });

      test('reads item_content alias when content_name is absent', () {
        final comp = ItemComposition.fromJson({
          'content': {'id': 'cnt-4', 'item_content': 'Metformin'},
        });

        expect(comp.contentId, 'cnt-4');
        expect(comp.contentName, 'Metformin');
      });

      test('reads item_strength alias when strength_name is absent', () {
        final comp = ItemComposition.fromJson({
          'strength': {'id': 'str-4', 'item_strength': '1000mg'},
        });

        expect(comp.strengthId, 'str-4');
        expect(comp.strengthName, '1000mg');
      });
    });

    group('nested content List (Supabase join)', () {
      test('reads first element of content List', () {
        final comp = ItemComposition.fromJson({
          'content': [
            {'id': 'cnt-5', 'content_name': 'Aspirin'},
          ],
          'strength': [
            {'id': 'str-5', 'strength_name': '100mg'},
          ],
        });

        expect(comp.contentId, 'cnt-5');
        expect(comp.contentName, 'Aspirin');
        expect(comp.strengthId, 'str-5');
        expect(comp.strengthName, '100mg');
      });

      test('handles empty content List without crashing', () {
        final comp = ItemComposition.fromJson({
          'content': <dynamic>[],
          'strength_id': 'str-6',
          'strength_name': '200mg',
        });

        expect(comp.contentId, isNull);
        expect(comp.contentName, isNull);
        expect(comp.strengthId, 'str-6');
        expect(comp.strengthName, '200mg');
      });
    });

    group('priority: nested over flat', () {
      test('nested content overrides flat content_name', () {
        final comp = ItemComposition.fromJson({
          'content_name': 'FlatName',
          'content': {'id': 'cnt-7', 'content_name': 'NestedName'},
        });

        expect(comp.contentName, 'NestedName');
      });

      test('top-level content_id is used when nested map has no id', () {
        final comp = ItemComposition.fromJson({
          'content_id': 'cnt-8',
          'content': {'content_name': 'SomeContent'},
        });

        expect(comp.contentId, 'cnt-8');
        expect(comp.contentName, 'SomeContent');
      });
    });
  });

  group('ItemComposition.toJson', () {
    test('emits only non-null ids', () {
      final comp = ItemComposition(
        contentId: 'cnt-9',
        strengthId: 'str-9',
        contentName: 'Cetirizine',
        strengthName: '10mg',
      );

      expect(comp.toJson(), {
        'content_id': 'cnt-9',
        'strength_id': 'str-9',
      });
    });

    test('omits null ids from output', () {
      final comp = ItemComposition(
        contentId: null,
        strengthId: 'str-10',
      );

      expect(comp.toJson(), {'strength_id': 'str-10'});
      expect(comp.toJson().containsKey('content_id'), isFalse);
    });

    test('returns empty map when both ids are null', () {
      final comp = ItemComposition();

      expect(comp.toJson(), isEmpty);
    });
  });

  group('ItemComposition.copyWith', () {
    test('replaces only specified fields', () {
      final original = ItemComposition(
        contentId: 'cnt-a',
        strengthId: 'str-a',
        contentName: 'Original',
        strengthName: '5mg',
      );

      final updated = original.copyWith(contentName: 'Updated');

      expect(updated.contentId, 'cnt-a');
      expect(updated.strengthId, 'str-a');
      expect(updated.contentName, 'Updated');
      expect(updated.strengthName, '5mg');
    });
  });
}
