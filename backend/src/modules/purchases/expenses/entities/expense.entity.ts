export interface ExpenseAttachmentEntity {
  id: string;
  expense_id: string;
  file_name: string;
  original_file_name?: string | null;
  file_url: string;
  file_type?: string | null;
  file_size?: number | null;
  uploaded_by?: string | null;
  remarks?: string | null;
  is_delete?: boolean | null;
  created_at?: string | null;
}

export interface ExpenseItemEntity {
  id: string;
  expense_id: string;
  line_no: number;
  expense_account_id: string;
  notes?: string | null;
  tax_id?: string | null;
  tax_amount?: number | null;
  amount: number;
}

export interface ExpenseMileageEntity {
  id: string;
  expense_id: string;
  employee_id?: string | null;
  calculation_type: string;
  distance: number;
  distance_unit: string;
  rate_per_km?: number | null;
  odometer_start?: number | null;
  odometer_end?: number | null;
  amount?: number | null;
  created_at?: string | null;
  updated_at?: string | null;
}

export interface ExpenseEntity {
  id: string;
  entity_id: string;
  expense_number?: string | null;
  expense_date: string;
  expense_mode: string;
  status: string;
  is_itemized: boolean;
  expense_account_id?: string | null;
  paid_through_account_id?: string | null;
  amount: number;
  currency_code?: string | null;
  expense_type: string;
  hsn_sac_code?: string | null;
  vendor_id?: string | null;
  customer_id?: string | null;
  mark_up_by?: number | null;
  gst_treatment?: string | null;
  source_of_supply?: string | null;
  destination_of_supply?: string | null;
  reverse_charge?: boolean | null;
  tax_id?: string | null;
  amount_tax_mode?: string | null;
  invoice_number?: string | null;
  notes?: string | null;
  is_billable?: boolean | null;
  subtotal?: number | null;
  tax_amount?: number | null;
  total_amount?: number | null;
  recurring_expense_id?: string | null;
  created_by?: string | null;
  updated_by?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
  expense_account_name?: string | null;
  paid_through_account_name?: string | null;
  vendor_name?: string | null;
  customer_name?: string | null;
  created_by_name?: string | null;
  updated_by_name?: string | null;
  is_delete?: boolean | null;
  items?: ExpenseItemEntity[];
  attachments?: ExpenseAttachmentEntity[];
  mileage?: ExpenseMileageEntity | null;
}
