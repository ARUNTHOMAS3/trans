import {
  Controller,
  Get,
  Post,
  Body,
  BadRequestException,
} from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";

@Controller("shipment-preferences")
export class ShipmentPreferencesController {
  constructor(private readonly supabaseService: SupabaseService) {}

  @Get()
  async findAll() {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("shipment_preferences")
      .select("*")
      .eq("is_active", true)
      .order("name", { ascending: true });

    if (error) throw error;
    return data;
  }

  @Post("sync")
  async sync(@Body("items") items: any[]) {
    if (!items || !Array.isArray(items)) {
      throw new BadRequestException("items must be an array");
    }

    const { data, error } = await this.supabaseService
      .getClient()
      .from("shipment_preferences")
      .upsert(items)
      .select();

    if (error) throw error;
    return data;
  }
}
