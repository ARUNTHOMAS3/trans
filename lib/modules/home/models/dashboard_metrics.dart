// PATH: lib/modules/dashboard/models/dashboard_metrics.dart

import 'package:equatable/equatable.dart';

class DashboardMetrics extends Equatable {
  final FinancialMetrics financial;
  final SalesMetrics sales;
  final InventoryMetrics inventory;
  final OperationsMetrics operations;
  final DateTime lastUpdated;

  const DashboardMetrics({
    required this.financial,
    required this.sales,
    required this.inventory,
    required this.operations,
    required this.lastUpdated,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      financial: FinancialMetrics.fromJson(json['financial'] as Map<String, dynamic>),
      sales: SalesMetrics.fromJson(json['sales'] as Map<String, dynamic>),
      inventory: InventoryMetrics.fromJson(json['inventory'] as Map<String, dynamic>),
      operations: OperationsMetrics.fromJson(json['operations'] as Map<String, dynamic>),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financial': financial.toJson(),
      'sales': sales.toJson(),
      'inventory': inventory.toJson(),
      'operations': operations.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  DashboardMetrics copyWith({
    FinancialMetrics? financial,
    SalesMetrics? sales,
    InventoryMetrics? inventory,
    OperationsMetrics? operations,
    DateTime? lastUpdated,
  }) {
    return DashboardMetrics(
      financial: financial ?? this.financial,
      sales: sales ?? this.sales,
      inventory: inventory ?? this.inventory,
      operations: operations ?? this.operations,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        financial,
        sales,
        inventory,
        operations,
        lastUpdated,
      ];
}

class FinancialMetrics extends Equatable {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final double profitMargin;
  final double accountsReceivable;
  final double accountsPayable;
  final double cashBalance;

  const FinancialMetrics({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMargin,
    required this.accountsReceivable,
    required this.accountsPayable,
    required this.cashBalance,
  });

  factory FinancialMetrics.fromJson(Map<String, dynamic> json) {
    return FinancialMetrics(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['netProfit'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profitMargin'] as num?)?.toDouble() ?? 0.0,
      accountsReceivable: (json['accountsReceivable'] as num?)?.toDouble() ?? 0.0,
      accountsPayable: (json['accountsPayable'] as num?)?.toDouble() ?? 0.0,
      cashBalance: (json['cashBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'totalExpenses': totalExpenses,
      'netProfit': netProfit,
      'profitMargin': profitMargin,
      'accountsReceivable': accountsReceivable,
      'accountsPayable': accountsPayable,
      'cashBalance': cashBalance,
    };
  }

  @override
  List<Object?> get props => [
        totalRevenue,
        totalExpenses,
        netProfit,
        profitMargin,
        accountsReceivable,
        accountsPayable,
        cashBalance,
      ];
}

class SalesMetrics extends Equatable {
  final int totalOrders;
  final double totalSales;
  final int pendingOrders;
  final int completedOrders;
  final double averageOrderValue;
  final List<TopProduct> topProducts;
  final List<SalesTrend> salesTrends;

  const SalesMetrics({
    required this.totalOrders,
    required this.totalSales,
    required this.pendingOrders,
    required this.completedOrders,
    required this.averageOrderValue,
    required this.topProducts,
    required this.salesTrends,
  });

  factory SalesMetrics.fromJson(Map<String, dynamic> json) {
    return SalesMetrics(
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      topProducts: (json['topProducts'] as List<dynamic>?)
          ?.map((item) => TopProduct.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      salesTrends: (json['salesTrends'] as List<dynamic>?)
          ?.map((item) => SalesTrend.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrders': totalOrders,
      'totalSales': totalSales,
      'pendingOrders': pendingOrders,
      'completedOrders': completedOrders,
      'averageOrderValue': averageOrderValue,
      'topProducts': topProducts.map((p) => p.toJson()).toList(),
      'salesTrends': salesTrends.map((t) => t.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        totalOrders,
        totalSales,
        pendingOrders,
        completedOrders,
        averageOrderValue,
        topProducts,
        salesTrends,
      ];
}

class InventoryMetrics extends Equatable {
  final int totalItems;
  final int lowStockItems;
  final int outOfStockItems;
  final double inventoryValue;
  final double turnoverRate;
  final List<LowStockItem> lowStockAlerts;

  const InventoryMetrics({
    required this.totalItems,
    required this.lowStockItems,
    required this.outOfStockItems,
    required this.inventoryValue,
    required this.turnoverRate,
    required this.lowStockAlerts,
  });

  factory InventoryMetrics.fromJson(Map<String, dynamic> json) {
    return InventoryMetrics(
      totalItems: json['totalItems'] as int? ?? 0,
      lowStockItems: json['lowStockItems'] as int? ?? 0,
      outOfStockItems: json['outOfStockItems'] as int? ?? 0,
      inventoryValue: (json['inventoryValue'] as num?)?.toDouble() ?? 0.0,
      turnoverRate: (json['turnoverRate'] as num?)?.toDouble() ?? 0.0,
      lowStockAlerts: (json['lowStockAlerts'] as List<dynamic>?)
          ?.map((item) => LowStockItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'lowStockItems': lowStockItems,
      'outOfStockItems': outOfStockItems,
      'inventoryValue': inventoryValue,
      'turnoverRate': turnoverRate,
      'lowStockAlerts': lowStockAlerts.map((a) => a.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        totalItems,
        lowStockItems,
        outOfStockItems,
        inventoryValue,
        turnoverRate,
        lowStockAlerts,
      ];
}

class OperationsMetrics extends Equatable {
  final int activeUsers;
  final int pendingApprovals;
  final int systemAlerts;
  final double uptimePercentage;
  final List<SystemAlert> alerts;

  const OperationsMetrics({
    required this.activeUsers,
    required this.pendingApprovals,
    required this.systemAlerts,
    required this.uptimePercentage,
    required this.alerts,
  });

  factory OperationsMetrics.fromJson(Map<String, dynamic> json) {
    return OperationsMetrics(
      activeUsers: json['activeUsers'] as int? ?? 0,
      pendingApprovals: json['pendingApprovals'] as int? ?? 0,
      systemAlerts: json['systemAlerts'] as int? ?? 0,
      uptimePercentage: (json['uptimePercentage'] as num?)?.toDouble() ?? 0.0,
      alerts: (json['alerts'] as List<dynamic>?)
          ?.map((item) => SystemAlert.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeUsers': activeUsers,
      'pendingApprovals': pendingApprovals,
      'systemAlerts': systemAlerts,
      'uptimePercentage': uptimePercentage,
      'alerts': alerts.map((a) => a.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        activeUsers,
        pendingApprovals,
        systemAlerts,
        uptimePercentage,
        alerts,
      ];
}

// Supporting models
class TopProduct extends Equatable {
  final String id;
  final String name;
  final int quantitySold;
  final double revenue;

  const TopProduct({
    required this.id,
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      quantitySold: json['quantitySold'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantitySold': quantitySold,
      'revenue': revenue,
    };
  }

  @override
  List<Object?> get props => [id, name, quantitySold, revenue];
}

class SalesTrend extends Equatable {
  final String period;
  final double revenue;
  final int orders;

  const SalesTrend({
    required this.period,
    required this.revenue,
    required this.orders,
  });

  factory SalesTrend.fromJson(Map<String, dynamic> json) {
    return SalesTrend(
      period: json['period'] as String,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      orders: json['orders'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'revenue': revenue,
      'orders': orders,
    };
  }

  @override
  List<Object?> get props => [period, revenue, orders];
}

class LowStockItem extends Equatable {
  final String id;
  final String name;
  final int currentStock;
  final int reorderLevel;
  final String warehouse;

  const LowStockItem({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.reorderLevel,
    required this.warehouse,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      id: json['id'] as String,
      name: json['name'] as String,
      currentStock: json['currentStock'] as int? ?? 0,
      reorderLevel: json['reorderLevel'] as int? ?? 0,
      warehouse: json['warehouse'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currentStock': currentStock,
      'reorderLevel': reorderLevel,
      'warehouse': warehouse,
    };
  }

  @override
  List<Object?> get props => [id, name, currentStock, reorderLevel, warehouse];
}

class SystemAlert extends Equatable {
  final String id;
  final String title;
  final String message;
  final String severity;
  final DateTime timestamp;

  const SystemAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
  });

  factory SystemAlert.fromJson(Map<String, dynamic> json) {
    return SystemAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, message, severity, timestamp];
}
