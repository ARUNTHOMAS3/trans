export interface RecurringExpense {
  id: string;
  profile_name: string;
  entity_id: string;
  repeat_every: number;
  repeat_type: string;
  start_date: string;
  end_date?: string;
  never_expires: boolean;
  next_run_date?: string;
  last_run_date?: string;
  status: string;
  expense_account_id: string;
  amount: number;
  currency_code: string;
  paid_through_account_id: string;
  expense_type: string;
  hsn_sac_code?: string;
  vendor_id?: string;
  gst_treatment?: string;
  source_of_supply?: string;
  destination_of_supply?: string;
  reverse_charge?: boolean;
  tax_id?: string;
  amount_tax_mode: string;
  invoice_number?: string;
  notes?: string;
  customer_id?: string;
  is_billable?: boolean;
  expense_account_name?: string;
  paid_through_account_name?: string;
  vendor_name?: string;
  customer_name?: string;
  created_by_name?: string;
  updated_by_name?: string;
  auto_create?: boolean;
  created_by?: string;
  updated_by?: string;
  created_at?: string;
  updated_at?: string;
}

export interface RecurringExpenseReceipt {
  id: string;
  recurring_expense_id: string;
  file_name?: string;
  file_url: string;
  file_size?: number;
  uploaded_by?: string;
  uploaded_at?: string;
}

export interface RecurringExpenseRun {
  id: string;
  recurring_expense_id: string;
  expense_id?: string;
  run_date: string;
  generated_amount?: number;
  status: string;
  remarks?: string;
  created_at?: string;
}
