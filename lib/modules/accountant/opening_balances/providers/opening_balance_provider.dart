import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/accountant/repositories/accountant_repository.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';

class OpeningBalanceState {
  static const _unset = Object();

  final Map<String, double> debitBalances;
  final Map<String, double> creditBalances;
  final DateTime openingDate;
  final bool isLoading;
  final Object? error;

  OpeningBalanceState({
    required this.debitBalances,
    required this.creditBalances,
    required this.openingDate,
    this.isLoading = false,
    this.error,
  });

  OpeningBalanceState copyWith({
    Map<String, double>? debitBalances,
    Map<String, double>? creditBalances,
    DateTime? openingDate,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return OpeningBalanceState(
      debitBalances: debitBalances ?? this.debitBalances,
      creditBalances: creditBalances ?? this.creditBalances,
      openingDate: openingDate ?? this.openingDate,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error,
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
          isLoading: true,
        ),
      ) {
    loadBalances();
  }

  Future<void> loadBalances() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final payload = await _repository.getOpeningBalances();
      final rawDate = payload['openingDate'] ?? payload['opening_date'];
      state = state.copyWith(
        debitBalances: _parseBalanceMap(payload['debits']),
        creditBalances: _parseBalanceMap(payload['credits']),
        openingDate: rawDate == null
            ? DateTime(DateTime.now().year, 4, 1)
            : DateTime.tryParse(rawDate.toString()) ??
                  DateTime(DateTime.now().year, 4, 1),
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

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
    state = state.copyWith(error: null);
  }

  Map<String, double> _parseBalanceMap(dynamic value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        entry.key.toString():
            double.tryParse(entry.value?.toString() ?? '0') ?? 0,
    };
  }
}

final openingBalanceProvider =
    StateNotifierProvider<OpeningBalanceNotifier, OpeningBalanceState>((ref) {
      ref.watch(authUserProvider.select((user) => user?.activeEntityId));
      final repository = ref.watch(accountantRepositoryProvider);
      return OpeningBalanceNotifier(repository);
    });
