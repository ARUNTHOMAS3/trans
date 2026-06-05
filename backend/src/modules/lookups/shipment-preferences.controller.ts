import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
} from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import * as crypto from "crypto";

@Controller("shipment-preferences")
export class ShipmentPreferencesController {
  constructor(private readonly supabaseService: SupabaseService) {}

  @Get()
  async list() {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("carrier")
      .select("*")
      .order("name", { ascending: true });

    if (error) throw error;
    return data ?? [];
  }

  @Post("sync")
  async sync(@Body("items") items: Array<Record<string, any>>) {
    if (!Array.isArray(items)) {
      throw new BadRequestException("items must be an array");
    }

    if (items.length === 0) return [];
    const cleanedItems = items.map((item) => {
      const cleaned = { ...item };
      
      // Remove is_active / isActive since column was deleted from the carrier table
      delete cleaned.is_active;
      delete cleaned.isActive;
      delete cleaned.createdAt;

      // Generate UUID in backend for new items so PostgREST bulk insert doesn't insert null
      if (
        !cleaned.id ||
        cleaned.id === "null" ||
        (typeof cleaned.id === "string" && (cleaned.id.startsWith("new_") || !cleaned.id.includes("-")))
      ) {
        cleaned.id = crypto.randomUUID();
      }

      // Generate created_at in backend if missing/null/empty/string-null to avoid PostgREST null-filling
      if (!cleaned.created_at || cleaned.created_at === "null" || cleaned.created_at === "") {
        cleaned.created_at = new Date().toISOString();
      }
      return cleaned;
    });

    const { data, error } = await this.supabaseService
      .getClient()
      .from("carrier")
      .upsert(cleanedItems)
      .select();

    if (error) throw error;
    return data ?? [];
  }
}
