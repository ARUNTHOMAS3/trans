enum RecurringExpenseStatus { active, stopped, expired }

enum RecurringRepeatType { day, week, month, year }

enum ExpenseType { goods, services }

enum AmountTaxMode { exclusive, inclusive }

enum RunStatus { success, failed, skipped }

extension RecurringExpenseStatusX on RecurringExpenseStatus {
  String get value => switch (this) {
    RecurringExpenseStatus.active => 'ACTIVE',
    RecurringExpenseStatus.stopped => 'STOPPED',
    RecurringExpenseStatus.expired => 'EXPIRED',
  };

  String get displayLabel => switch (this) {
    RecurringExpenseStatus.active => 'Active',
    RecurringExpenseStatus.stopped => 'Stopped',
    RecurringExpenseStatus.expired => 'Expired',
  };

  static RecurringExpenseStatus fromValue(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == 'STOPPED' ||
        normalized == 'PAUSED' ||
        normalized == 'COMPLETED' ||
        normalized == 'CANCELLED') {
      return RecurringExpenseStatus.stopped;
    }
    if (normalized == 'EXPIRED') {
      return RecurringExpenseStatus.expired;
    }
    return RecurringExpenseStatus.active;
  }
}

extension RecurringRepeatTypeX on RecurringRepeatType {
  String get value => switch (this) {
    RecurringRepeatType.day => 'DAY',
    RecurringRepeatType.week => 'WEEK',
    RecurringRepeatType.month => 'MONTH',
    RecurringRepeatType.year => 'YEAR',
  };

  String get displayLabel => switch (this) {
    RecurringRepeatType.day => 'Day',
    RecurringRepeatType.week => 'Week',
    RecurringRepeatType.month => 'Month',
    RecurringRepeatType.year => 'Year',
  };

  String get customUnitLabel => switch (this) {
    RecurringRepeatType.day => 'Day(s)',
    RecurringRepeatType.week => 'Week(s)',
    RecurringRepeatType.month => 'Month(s)',
    RecurringRepeatType.year => 'Year(s)',
  };

  static RecurringRepeatType fromValue(String? value) {
    return RecurringRepeatType.values.firstWhere(
      (RecurringRepeatType item) => item.value == value?.toUpperCase(),
      orElse: () => RecurringRepeatType.week,
    );
  }
}

extension ExpenseTypeX on ExpenseType {
  String get value => switch (this) {
    ExpenseType.goods => 'GOODS',
    ExpenseType.services => 'SERVICES',
  };

  String get displayLabel => switch (this) {
    ExpenseType.goods => 'Goods',
    ExpenseType.services => 'Services',
  };

  static ExpenseType fromValue(String? value) {
    return ExpenseType.values.firstWhere(
      (ExpenseType item) => item.value == value?.toUpperCase(),
      orElse: () => ExpenseType.goods,
    );
  }
}

extension AmountTaxModeX on AmountTaxMode {
  String get value => switch (this) {
    AmountTaxMode.exclusive => 'EXCLUSIVE',
    AmountTaxMode.inclusive => 'INCLUSIVE',
  };

  String get displayLabel => switch (this) {
    AmountTaxMode.exclusive => 'Tax Exclusive',
    AmountTaxMode.inclusive => 'Tax Inclusive',
  };

  static AmountTaxMode fromValue(String? value) {
    return AmountTaxMode.values.firstWhere(
      (AmountTaxMode item) => item.value == value?.toUpperCase(),
      orElse: () => AmountTaxMode.exclusive,
    );
  }
}

extension RunStatusX on RunStatus {
  String get value => switch (this) {
    RunStatus.success => 'SUCCESS',
    RunStatus.failed => 'FAILED',
    RunStatus.skipped => 'SKIPPED',
  };

  static RunStatus fromValue(String? value) {
    return RunStatus.values.firstWhere(
      (RunStatus item) => item.value == value?.toUpperCase(),
      orElse: () => RunStatus.success,
    );
  }
}
