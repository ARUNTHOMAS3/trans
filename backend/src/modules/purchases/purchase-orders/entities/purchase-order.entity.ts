export interface PurchaseOrder {
  id: string;
  vendor_id: string;
  order_number: string;
  order_date: string;
  expected_delivery_date?: string;
  reference_number?: string;
  terms?: string;
  notes?: string;
  subtotal: number;
  tax_amount?: number;
  total_amount: number;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface PurchaseOrderItem {
  id: string;
  purchase_order_id: string;
  item_id?: string;
  item_name: string;
  quantity: number;
  rate: number;
  discount_percent?: number;
  amount: number;
  created_at: string;
}
