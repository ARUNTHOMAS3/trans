import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import '../../../core/services/api_client.dart';

class DashboardState {
  final double receivables;
  final double payables;
  final double cashOnHand;
  final double purchaseReceivablesAmount;
  final double billsTotalAmount;
  final int picklistsCount;
  final int packagesCount;
  final int salesInvoicesCount;
  final double salesInvoicesAmount;
  final double salesOrdersAmount;
  final double purchaseOrdersAmount;
  final List<Map<String, dynamic>> salesTrend;
  final List<Map<String, dynamic>> topCustomers;
  final List<Map<String, dynamic>> topItems;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.receivables = 0,
    this.payables = 0,
    this.cashOnHand = 0,
    this.purchaseReceivablesAmount = 0,
    this.billsTotalAmount = 0,
    this.picklistsCount = 0,
    this.packagesCount = 0,
    this.salesInvoicesCount = 0,
    this.salesInvoicesAmount = 0,
    this.salesOrdersAmount = 0,
    this.purchaseOrdersAmount = 0,
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
    double? purchaseReceivablesAmount,
    double? billsTotalAmount,
    int? picklistsCount,
    int? packagesCount,
    int? salesInvoicesCount,
    double? salesInvoicesAmount,
    double? salesOrdersAmount,
    double? purchaseOrdersAmount,
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
      purchaseReceivablesAmount:
          purchaseReceivablesAmount ?? this.purchaseReceivablesAmount,
      billsTotalAmount: billsTotalAmount ?? this.billsTotalAmount,
      picklistsCount: picklistsCount ?? this.picklistsCount,
      packagesCount: packagesCount ?? this.packagesCount,
      salesInvoicesCount: salesInvoicesCount ?? this.salesInvoicesCount,
      salesInvoicesAmount: salesInvoicesAmount ?? this.salesInvoicesAmount,
      salesOrdersAmount: salesOrdersAmount ?? this.salesOrdersAmount,
      purchaseOrdersAmount: purchaseOrdersAmount ?? this.purchaseOrdersAmount,
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
  bool _disposed = false;

  DashboardNotifier(this._dio) : super(DashboardState());

  void _setStateSafe(DashboardState next) {
    if (_disposed) return;
    try {
      state = next;
    } on StateError {
      // Ignore stale async writes after provider disposal during auth/tenant switches.
    }
  }

  Future<void> fetchSummary() async {
    if (_disposed) return;
    _setStateSafe(state.copyWith(isLoading: true, error: null));
    try {
      final response = await _dio.get(
        '/reports/dashboard-summary',
        options: Options(extra: {'cache': false}),
      );
      final data = response.data;
      if (_disposed) return;

      _setStateSafe(
        state.copyWith(
          receivables: (data['receivables'] ?? 0).toDouble(),
          payables: (data['payables'] ?? 0).toDouble(),
          cashOnHand: (data['cashOnHand'] ?? 0).toDouble(),
          purchaseReceivablesAmount: (data['purchaseReceivablesAmount'] ?? 0)
              .toDouble(),
          billsTotalAmount: (data['billsTotalAmount'] ?? 0).toDouble(),
          picklistsCount: (data['picklistsCount'] as num?)?.toInt() ?? 0,
          packagesCount: (data['packagesCount'] as num?)?.toInt() ?? 0,
          salesInvoicesCount:
              (data['salesInvoicesCount'] as num?)?.toInt() ?? 0,
          salesInvoicesAmount: (data['salesInvoicesAmount'] ?? 0).toDouble(),
          salesOrdersAmount: (data['salesOrdersAmount'] ?? 0).toDouble(),
          purchaseOrdersAmount: (data['purchaseOrdersAmount'] ?? 0).toDouble(),
          salesTrend: List<Map<String, dynamic>>.from(data['salesTrend'] ?? []),
          topCustomers: List<Map<String, dynamic>>.from(
            data['topCustomers'] ?? [],
          ),
          topItems: List<Map<String, dynamic>>.from(data['topItems'] ?? []),
          isLoading: false,
        ),
      );
    } catch (e) {
      if (_disposed) return;
      _setStateSafe(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      final dio = ref.watch(dioProvider);
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      final selectedEntityId = ref.watch(entityProvider).entityId?.trim();
      final authUser = ref.watch(authUserProvider);
      final activeEntityId = authUser?.activeEntityId?.trim();
      final orgEntityId = authUser?.orgEntityId?.trim();
      final activeTenantType = authUser?.activeTenantType?.trim().toUpperCase();
      final effectiveEntityId =
          (selectedEntityId != null && selectedEntityId.isNotEmpty)
          ? selectedEntityId
          : (activeEntityId != null && activeEntityId.isNotEmpty)
          ? activeEntityId
          : (activeTenantType == 'ORG' &&
                orgEntityId != null &&
                orgEntityId.isNotEmpty)
          ? orgEntityId
          : null;
      final notifier = DashboardNotifier(dio);
      if (isAuthenticated && (effectiveEntityId?.isNotEmpty ?? false)) {
        notifier.fetchSummary();
      }
      return notifier;
    });
