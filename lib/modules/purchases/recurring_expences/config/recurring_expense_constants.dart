class RecurringExpenseStatusMapping {
  static const String active = 'ACTIVE';
  static const String stopped = 'STOPPED';
  static const String expired = 'EXPIRED';

  static const List<String> filterValues = <String>[
    'all',
    'active',
    'stopped',
    'expired',
  ];

  static const Map<String, String> labels = <String, String>{
    active: 'Active',
    stopped: 'Stopped',
    expired: 'Expired',
  };
}

class RecurringExpenseFrequencyMapping {
  static const String daily = 'Daily';
  static const String weekly = 'Weekly';
  static const String monthly = 'Monthly';
  static const String yearly = 'Yearly';
  static const String custom = 'Custom';

  static const List<String> values = <String>[
    daily,
    weekly,
    monthly,
    yearly,
    custom,
  ];
}

class RecurringExpenseModuleDefaults {
  static const String orgSystemId = '6000000000';
  static const String defaultCurrency = 'INR';
  static const String defaultRepeatEvery = 'Week';
  static const String defaultCustomRepeatUnit = 'Week(s)';
  static const String defaultAmountIs = 'Tax Exclusive';
  static const String defaultExpenseType = 'Goods';
  static const String defaultItcOption = 'Eligible For ITC';

  static const List<String> fallbackTaxes = <String>[
    'GST 0%',
    'GST 5%',
    'GST 12%',
    'GST 18%',
    'GST 28%',
    'IGST 18%',
    'CGST 9% + SGST 9%',
  ];

  static const List<String> inputTaxCreditOptions = <String>[
    'Eligible For ITC',
    'Ineligible - As per Section 17 (5)',
    'Ineligible - Others',
  ];

  static const List<String> bulkUpdateFields = <String>[
    'Expense Account',
    'Paid Through',
    'End Date',
    'Repeat Every',
    'Notes',
    'Vendor',
    'Customer',
    'Expense Type',
    'Billable',
  ];
}
