import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../modules/supabase/supabase.service";

@Injectable()
export class CurrenciesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll() {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("currencies")
      .select("*")
      .eq("is_active", true)
      .order("code", { ascending: true });

    if (error) throw error;
    return data;
  }
}
