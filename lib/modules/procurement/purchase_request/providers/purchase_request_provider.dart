import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PrStatus { awaitingApproval, approved, onHold, rejected }

class PurchaseRequestRecord {
  PurchaseRequestRecord({
    required this.requestNumber,
    required this.submitter,
    required this.submittedOn,
    required this.expectedDate,
    required this.assignee,
    this.status = PrStatus.awaitingApproval,
    this.amount = 0.0,
  });

  final String requestNumber;
  final String submitter;
  final String submittedOn;
  final String expectedDate;
  final String assignee;
  PrStatus status;
  final double amount;

  // Approver is the same as assignee in the current create form
  String get approver => assignee;
}

class PurchaseRequestNotifier
    extends StateNotifier<List<PurchaseRequestRecord>> {
  PurchaseRequestNotifier() : super([]);

  int _seq = 0;

  String nextNumber() {
    _seq++;
    return 'PR-${_seq.toString().padLeft(5, '0')}';
  }

  void add(PurchaseRequestRecord record) {
    state = [...state, record];
  }
}

final purchaseRequestProvider = StateNotifierProvider<PurchaseRequestNotifier,
    List<PurchaseRequestRecord>>(
  (ref) => PurchaseRequestNotifier(),
);

/// Bumped whenever a purchase request is created or edited, so open list pages
/// reload instead of showing what they fetched when they were first built.
///
/// The create/edit page is a child route of the list, so returning to the list
/// pops back to a State that is still alive — `initState` never runs again and
/// edits (a newly picked assignee, for example) would need a manual refresh.
final purchaseRequestListRefreshProvider = StateProvider<int>((ref) => 0);

String prDateToday() {
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.year}';
}
