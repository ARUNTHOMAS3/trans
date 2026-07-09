class ExpenseMileageModel {
  const ExpenseMileageModel({
    required this.distance,
    required this.distanceUnit,
    required this.calculationType,
    this.id = '',
    this.employeeId,
    this.ratePerKm = 0,
    this.odometerStart,
    this.odometerEnd,
  });

  final String id;
  final String? employeeId;
  final String calculationType;
  final double distance;
  final String distanceUnit;
  final double ratePerKm;
  final double? odometerStart;
  final double? odometerEnd;

  factory ExpenseMileageModel.fromJson(Map<String, dynamic> json) {
    return ExpenseMileageModel(
      id: (json['id'] ?? '').toString(),
      employeeId: (json['employee_id'] ?? json['employeeId'])?.toString(),
      calculationType:
          (json['calculation_type'] ?? json['calculationType'] ?? '')
              .toString(),
      distance: (json['distance'] as num?)?.toDouble() ??
          double.tryParse((json['distance'] ?? '0').toString()) ??
          0,
      distanceUnit: (json['distance_unit'] ?? json['distanceUnit'] ?? '')
          .toString(),
      ratePerKm: (json['rate_per_km'] as num?)?.toDouble() ??
          double.tryParse(
                (json['rate_per_km'] ?? '0')
                    .toString(),
              ) ??
          0,
      odometerStart: (json['odometer_start'] as num?)?.toDouble() ??
          double.tryParse(
            (json['odometer_start'] ?? '').toString(),
          ),
      odometerEnd: (json['odometer_end'] as num?)?.toDouble() ??
          double.tryParse(
            (json['odometer_end'] ?? '').toString(),
          ),
    );
  }

  Map<String, dynamic> toRequestJson() => <String, dynamic>{
        if (employeeId != null && employeeId!.trim().isNotEmpty)
          'employee_id': employeeId,
        'calculation_type': calculationType,
        'distance': distance,
        'distance_unit': distanceUnit,
        'rate_per_km': ratePerKm,
        if (odometerStart != null) 'odometer_start': odometerStart,
        if (odometerEnd != null) 'odometer_end': odometerEnd,
      };
}
