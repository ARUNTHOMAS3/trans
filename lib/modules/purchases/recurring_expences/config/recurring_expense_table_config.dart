import 'package:zerpai_erp/shared/models/column_config.dart';

const double recurringExpensesPageActionButtonWidth = 88.0;
const double recurringExpensesPageActionButtonHeight = 42.0;
const double recurringExpensesPageMoreMenuSize = 40.0;
const double recurringExpensesSelectionColumnWidth = 36.0;

const Map<String, double> recurringExpenseColumnWidths = <String, double>{
  'profile': 180,
  'expense': 220,
  'vendor': 180,
  'frequency': 120,
  'last': 180,
  'next': 180,
  'status': 120,
  'amount': 120,
  'customer': 170,
};

ColumnConfig cloneRecurringExpenseColumn(ColumnConfig column) {
  return ColumnConfig(
    id: column.id,
    label: column.label,
    isVisible: column.isVisible,
    orderIndex: column.orderIndex,
    isLocked: column.isLocked,
  );
}

List<ColumnConfig> buildRecurringExpenseColumns() {
  return <ColumnConfig>[
    ColumnConfig(
      id: 'profile',
      label: 'PROFILE NAME',
      isVisible: true,
      isLocked: true,
      orderIndex: 0,
    ),
    ColumnConfig(
      id: 'expense',
      label: 'EXPENSE ACCOUNT',
      isVisible: true,
      isLocked: true,
      orderIndex: 1,
    ),
    ColumnConfig(
      id: 'vendor',
      label: 'VENDOR NAME',
      isVisible: true,
      orderIndex: 2,
    ),
    ColumnConfig(
      id: 'frequency',
      label: 'FREQUENCY',
      isVisible: true,
      isLocked: true,
      orderIndex: 3,
    ),
    ColumnConfig(
      id: 'last',
      label: 'LAST EXPENSE DATE',
      isVisible: true,
      orderIndex: 4,
    ),
    ColumnConfig(
      id: 'next',
      label: 'NEXT EXPENSE DATE',
      isVisible: true,
      isLocked: true,
      orderIndex: 5,
    ),
    ColumnConfig(
      id: 'status',
      label: 'STATUS',
      isVisible: true,
      isLocked: true,
      orderIndex: 6,
    ),
    ColumnConfig(
      id: 'amount',
      label: 'AMOUNT',
      isVisible: true,
      isLocked: true,
      orderIndex: 7,
    ),
    ColumnConfig(
      id: 'customer',
      label: 'CUSTOMER NAME',
      isVisible: false,
      orderIndex: 8,
    ),
  ];
}
