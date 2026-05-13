import 'package:flutter_test/flutter_test.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/models/manual_journal_model.dart';

void main() {
  group('ManualJournal model', () {
    test('status mapping handles published as posted', () {
      expect(
        manualJournalStatusFromApi('published'),
        ManualJournalStatus.posted,
      );
    });

    test('computes totals from items', () {
      final journal = ManualJournal(
        id: '1',
        journalDate: DateTime.parse('2026-03-17T00:00:00.000Z'),
        journalNumber: 'MJ-1',
        items: [
          ManualJournalItem(
            id: 'i1',
            accountId: 'a1',
            accountName: 'Cash',
            debit: 100,
            credit: 0,
          ),
          ManualJournalItem(
            id: 'i2',
            accountId: 'a2',
            accountName: 'Sales',
            debit: 0,
            credit: 100,
          ),
        ],
        createdAt: DateTime.parse('2026-03-17T00:00:00.000Z'),
        updatedAt: DateTime.parse('2026-03-17T00:00:00.000Z'),
      );

      expect(journal.totalDebit, 100);
      expect(journal.totalCredit, 100);
      expect(journal.totalAmount, 100);
    });

    test('parses api shape correctly', () {
      final journal = ManualJournal.fromJson({
        'id': 'j1',
        'journal_number': 'MJ-42',
        'journal_date': '2026-03-17T00:00:00.000Z',
        'status': 'published',
        'items': [
          {
            'id': 'i1',
            'account_id': 'a1',
            'account_name': 'Cash',
            'debit': 10,
            'credit': 0,
          },
        ],
        'created_at': '2026-03-17T00:00:00.000Z',
        'updated_at': '2026-03-17T00:00:00.000Z',
      });

      expect(journal.journalNumber, 'MJ-42');
      expect(journal.status, ManualJournalStatus.posted);
      expect(journal.items.single.accountName, 'Cash');
    });
  });
}
