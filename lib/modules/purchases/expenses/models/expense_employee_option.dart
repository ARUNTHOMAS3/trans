class ExpenseEmployeeOption {
  const ExpenseEmployeeOption({
    required this.id,
    required this.fullName,
  });

  final String id;
  final String fullName;

  factory ExpenseEmployeeOption.fromJson(Map<String, dynamic> json) {
    return ExpenseEmployeeOption(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['fullName'] ?? '').toString(),
    );
  }
}
