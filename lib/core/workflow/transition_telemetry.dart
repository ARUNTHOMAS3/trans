import 'package:zerpai_erp/core/logging/app_logger.dart';

class TransitionTelemetryEvent {
  final String transactionType;
  final String transactionId;
  final String fromStatus;
  final String toStatus;
  final bool allowed;
  final String reason;
  final bool highRisk;
  final bool reversed;
  final DateTime timestamp;
  final String? branchId;
  final String? warehouseId;

  const TransitionTelemetryEvent({
    required this.transactionType,
    required this.transactionId,
    required this.fromStatus,
    required this.toStatus,
    required this.allowed,
    required this.reason,
    required this.timestamp,
    this.highRisk = false,
    this.reversed = false,
    this.branchId,
    this.warehouseId,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'transaction_type': transactionType,
      'transaction_id': transactionId,
      'from_status': fromStatus,
      'to_status': toStatus,
      'allowed': allowed,
      'reason': reason,
      'high_risk': highRisk,
      'reversed': reversed,
      'timestamp': timestamp.toIso8601String(),
      'branch_id': branchId,
      'warehouse_id': warehouseId,
    };
  }
}

class TransitionTelemetryEmitter {
  const TransitionTelemetryEmitter._();

  static void emit(TransitionTelemetryEvent event) {
    AppLogger.info(
      'Transition telemetry',
      module: 'workflow_telemetry',
      data: event.toJson(),
    );
  }
}
