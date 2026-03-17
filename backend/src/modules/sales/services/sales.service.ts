import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../../supabase/supabase.service";

@Injectable()
export class SalesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getSalesByType(type: string) {
    const client = this.supabaseService.getClient();
    
    // In a real app, we'd filter by orgId and outletId from headers/JWT
    const { data, error } = await client
      .from('sales_orders')
      .select('*')
      .eq('document_type', type)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  }
}
