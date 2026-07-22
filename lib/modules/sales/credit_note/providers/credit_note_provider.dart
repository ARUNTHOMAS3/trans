import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/sales/credit_note/models/credit_note_model.dart';
import 'package:zerpai_erp/modules/sales/credit_note/repositories/credit_note_repository.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

final creditNoteRepositoryProvider = Provider<CreditNoteRepository>((ref) {
  return CreditNoteRepositoryImpl(ApiClient());
});

final creditNotesListProvider =
    FutureProvider.family<List<CreditNoteModel>, String?>((ref, status) async {
      final repo = ref.watch(creditNoteRepositoryProvider);
      return repo.getCreditNotes(status: status);
    });

final createCreditNoteProvider =
    Provider<Future<String?> Function(Map<String, dynamic>)>((ref) {
      final repo = ref.read(creditNoteRepositoryProvider);
      return (payload) => repo.createCreditNote(payload);
    });
