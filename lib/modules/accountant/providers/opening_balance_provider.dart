import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/accountant_repository.dart';

class OpeningBalanceState {
  final Map<String, double> debitBalances;
  final Map<String, double> creditBalances;
  final DateTime openingDate;

  OpeningBalanceState({
    required this.debitBalances,
    required this.creditBalances,
    required this.openingDate,
  });

  OpeningBalanceState copyWith({
    Map<String, double>? debitBalances,
    Map<String, double>? creditBalances,
    DateTime? openingDate,
  }) {
    return OpeningBalanceState(
      debitBalances: debitBalances ?? this.debitBalances,
      creditBalances: creditBalances ?? this.creditBalances,
      openingDate: openingDate ?? this.openingDate,
    );
  }
}

class OpeningBalanceNotifier extends StateNotifier<OpeningBalanceState> {
  final AccountantRepository _repository;

  OpeningBalanceNotifier(this._repository)
    : super(
        OpeningBalanceState(
          debitBalances: {},
          creditBalances: {},
          openingDate: DateTime(DateTime.now().year, 4, 1),
        ),
      );

  void updateBalances({
    required Map<String, double> debitBalances,
    required Map<String, double> creditBalances,
    required DateTime openingDate,
  }) {
    state = state.copyWith(
      debitBalances: debitBalances,
      creditBalances: creditBalances,
      openingDate: openingDate,
    );
  }

  double getDebit(String accountId) => state.debitBalances[accountId] ?? 0.0;
  double getCredit(String accountId) => state.creditBalances[accountId] ?? 0.0;

  Future<void> saveBalances() async {
    await _repository.saveOpeningBalances(
      debits: state.debitBalances,
      credits: state.creditBalances,
      openingDate: state.openingDate,
    );
  }
}

final openingBalanceProvider =
    StateNotifierProvider<OpeningBalanceNotifier, OpeningBalanceState>((ref) {
      final repository = ref.watch(accountantRepositoryProvider);
      return OpeningBalanceNotifier(repository);
    });
