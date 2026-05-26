import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import '../../../shared/services/api_client.dart';

class DashboardState {
  final double receivables;
  final double payables;
  final double cashOnHand;
  final List<Map<String, dynamic>> salesTrend;
  final List<Map<String, dynamic>> topCustomers;
  final List<Map<String, dynamic>> topItems;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.receivables = 0,
    this.payables = 0,
    this.cashOnHand = 0,
    this.salesTrend = const [],
    this.topCustomers = const [],
    this.topItems = const [],
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    double? receivables,
    double? payables,
    double? cashOnHand,
    List<Map<String, dynamic>>? salesTrend,
    List<Map<String, dynamic>>? topCustomers,
    List<Map<String, dynamic>>? topItems,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      receivables: receivables ?? this.receivables,
      payables: payables ?? this.payables,
      cashOnHand: cashOnHand ?? this.cashOnHand,
      salesTrend: salesTrend ?? this.salesTrend,
      topCustomers: topCustomers ?? this.topCustomers,
      topItems: topItems ?? this.topItems,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Dio _dio;
  final String? orgId;
  final String? branchId;

  DashboardNotifier(this._dio, {this.orgId, this.branchId})
    : super(DashboardState());

  Future<void> fetchSummary() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get(
        '/reports/dashboard-summary',
        queryParameters: {
          if (orgId != null && orgId!.isNotEmpty) 'orgId': orgId,
          if (branchId != null && branchId!.isNotEmpty) 'branchId': branchId,
        },
      );
      final data = response.data;

      state = state.copyWith(
        receivables: (data['receivables'] ?? 0).toDouble(),
        payables: (data['payables'] ?? 0).toDouble(),
        cashOnHand: (data['cashOnHand'] ?? 0).toDouble(),
        salesTrend: List<Map<String, dynamic>>.from(data['salesTrend'] ?? []),
        topCustomers: List<Map<String, dynamic>>.from(data['topCustomers'] ?? []),
        topItems: List<Map<String, dynamic>>.from(data['topItems'] ?? []),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final branchIdProvider = Provider<String?>((ref) => null);

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      final dio = ref.watch(dioProvider);
      final authUser = ref.watch(authUserProvider);
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      final branchId = ref.watch(branchIdProvider);
      final notifier = DashboardNotifier(
        dio,
        orgId: authUser?.orgId,
        branchId: branchId ?? authUser?.defaultBusinessBranchId,
      );
      if (isAuthenticated) notifier.fetchSummary();
      return notifier;
    });
