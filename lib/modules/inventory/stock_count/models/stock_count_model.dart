enum StockCountStatus {
  yetToStart,
  inProgress,
  pendingApproval,
  approvalInProgress,
  completed,
  cancelled,
  expired;

  String get label {
    switch (this) {
      case StockCountStatus.yetToStart:
        return 'YET TO START';
      case StockCountStatus.inProgress:
        return 'Counting In Progress';
      case StockCountStatus.pendingApproval:
        return 'Pending Approval';
      case StockCountStatus.approvalInProgress:
        return 'Approval In Progress';
      case StockCountStatus.completed:
        return 'Completed';
      case StockCountStatus.cancelled:
        return 'Cancelled';
      case StockCountStatus.expired:
        return 'Expired';
    }
  }

  static StockCountStatus fromLabel(String label) {
    switch (label.toLowerCase().trim()) {
      case 'counting in progress':
      case 'in progress':
        return StockCountStatus.inProgress;
      case 'pending approval':
        return StockCountStatus.pendingApproval;
      case 'approval in progress':
        return StockCountStatus.approvalInProgress;
      case 'completed':
        return StockCountStatus.completed;
      case 'cancelled':
        return StockCountStatus.cancelled;
      case 'expired':
        return StockCountStatus.expired;
      case 'yet to start':
      default:
        return StockCountStatus.yetToStart;
    }
  }
}

class StockCount {
  final String id;
  final String stockCountNum;
  final String? recurringName;
  final String? description;
  final String? location;
  final String assignedTo;
  final StockCountStatus status;
  final DateTime countDate;
  final bool isRecurring;
  final String? scheduleType;
  final String? frequency;
  final DateTime? scheduleStartDate;
  final String? scheduleExpiry;
  final String? countGenerationTime;
  final Object? generateCountOn;
  final DateTime? nextCountDate;
  final bool isActive;
  final int totalItems;
  final double? accuracy;
  final String? warehouseId;
  final List<Map<String, dynamic>> items;

  const StockCount({
    required this.id,
    required this.stockCountNum,
    this.recurringName,
    this.description,
    this.location,
    this.warehouseId,
    required this.assignedTo,
    required this.status,
    required this.countDate,
    this.isRecurring = false,
    this.scheduleType,
    this.frequency,
    this.scheduleStartDate,
    this.scheduleExpiry,
    this.countGenerationTime,
    this.generateCountOn,
    this.nextCountDate,
    this.isActive = true,
    required this.totalItems,
    this.accuracy,
    this.items = const [],
  });

  StockCount copyWith({
    String? id,
    String? stockCountNum,
    String? recurringName,
    String? description,
    String? location,
    String? warehouseId,
    String? assignedTo,
    StockCountStatus? status,
    DateTime? countDate,
    bool? isRecurring,
    String? scheduleType,
    String? frequency,
    DateTime? scheduleStartDate,
    String? scheduleExpiry,
    String? countGenerationTime,
    Object? generateCountOn,
    DateTime? nextCountDate,
    bool? isActive,
    int? totalItems,
    double? accuracy,
    List<Map<String, dynamic>>? items,
  }) {
    return StockCount(
      id: id ?? this.id,
      stockCountNum: stockCountNum ?? this.stockCountNum,
      recurringName: recurringName ?? this.recurringName,
      description: description ?? this.description,
      location: location ?? this.location,
      warehouseId: warehouseId ?? this.warehouseId,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      countDate: countDate ?? this.countDate,
      isRecurring: isRecurring ?? this.isRecurring,
      scheduleType: scheduleType ?? this.scheduleType,
      frequency: frequency ?? this.frequency,
      scheduleStartDate: scheduleStartDate ?? this.scheduleStartDate,
      scheduleExpiry: scheduleExpiry ?? this.scheduleExpiry,
      countGenerationTime: countGenerationTime ?? this.countGenerationTime,
      generateCountOn: generateCountOn ?? this.generateCountOn,
      nextCountDate: nextCountDate ?? this.nextCountDate,
      isActive: isActive ?? this.isActive,
      totalItems: totalItems ?? this.totalItems,
      accuracy: accuracy ?? this.accuracy,
      items: items ?? this.items,
    );
  }
}
