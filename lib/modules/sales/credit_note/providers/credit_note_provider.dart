import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/sales/credit_note/models/credit_note_model.dart';
import 'package:zerpai_erp/modules/sales/credit_note/repositories/credit_note_repository.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

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

final deleteCreditNoteProvider = Provider<Future<void> Function(String)>((ref) {
  final repo = ref.read(creditNoteRepositoryProvider);
  return (id) => repo.deleteCreditNote(id);
});

final getCreditNoteProvider =
    Provider<Future<CreditNoteModel> Function(String)>((ref) {
  final repo = ref.read(creditNoteRepositoryProvider);
  return (id) => repo.getCreditNote(id);
});

final updateCreditNoteProvider =
    Provider<Future<void> Function(String, Map<String, dynamic>)>((ref) {
  final repo = ref.read(creditNoteRepositoryProvider);
  return (id, payload) => repo.updateCreditNote(id, payload);
});

final creditNoteJournalProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final repo = ref.watch(creditNoteRepositoryProvider);
  return repo.getCreditNoteJournal(id);
});

final creditNotesWarehousesProvider = FutureProvider<List<Warehouse>>((ref) async {
  final repository = ref.watch(creditNoteRepositoryProvider);
  return repository.getWarehouses();
});
