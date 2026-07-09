export const EXPENSE_MODES = ["RECORD_EXPENSE", "RECORD_MILEAGE"] as const;
export const EXPENSE_STATUSES = [
  "DRAFT",
  "RECORDED",
  "DELETED",
] as const;
export const AMOUNT_TAX_MODES = ["EXCLUSIVE", "INCLUSIVE"] as const;
export const EXPENSE_TYPES = ["GOODS", "SERVICES"] as const;
export const MILEAGE_CALCULATION_METHODS = [
  "DISTANCE_TRAVELLED",
  "ODOMETER_READING",
] as const;
export const MILEAGE_UNITS = ["KM", "MILE"] as const;

export type ExpenseMode = (typeof EXPENSE_MODES)[number];
export type ExpenseStatus = (typeof EXPENSE_STATUSES)[number];
export type AmountTaxMode = (typeof AMOUNT_TAX_MODES)[number];
export type ExpenseType = (typeof EXPENSE_TYPES)[number];
export type MileageCalculationMethod =
  (typeof MILEAGE_CALCULATION_METHODS)[number];
export type MileageUnit = (typeof MILEAGE_UNITS)[number];
