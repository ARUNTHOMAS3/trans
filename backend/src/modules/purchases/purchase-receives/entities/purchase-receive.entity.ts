export interface PurchaseReceiveItem {
  id: string;
  purchase_receive_id: string;
  item_id?: string;
  item_name: string;
  description?: string;
  ordered: number;
  received: number;
  in_transit: number;
  quantity_to_receive: number;
  created_at: string;
}

export interface PurchaseReceive {
  id: string;
  org_id?: string;
  vendor_name?: string;
  purchase_receive_number: string;
  received_date: string;
  purchase_order_id?: string;
  purchase_order_number?: string;
  status: string;
  notes?: string;
  items?: PurchaseReceiveItem[];
  created_at: string;
  updated_at: string;
}
