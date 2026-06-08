import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
} from "@nestjs/common";
import * as crypto from "crypto";
import { SupabaseService } from "../supabase/supabase.service";

@Controller("shipment-preferences")
export class ShipmentPreferencesController {
  constructor(private readonly supabaseService: SupabaseService) {}

  private readonly primaryTable = "carrier";
  private readonly fallbackTable = "shipment_preferences";

  private cleanItems(items: Array<Record<string, any>>) {
    return items.map((item) => {
      const cleaned = { ...item };

      delete cleaned.is_active;
      delete cleaned.isActive;
      delete cleaned.createdAt;
      delete cleaned.updatedAt;

      if (
        !cleaned.id ||
        cleaned.id === "null" ||
        (typeof cleaned.id === "string" &&
          (cleaned.id.startsWith("new_") || !cleaned.id.includes("-")))
      ) {
        cleaned.id = crypto.randomUUID();
      }

      if (
        !cleaned.created_at ||
        cleaned.created_at === "null" ||
        cleaned.created_at === ""
      ) {
        cleaned.created_at = new Date().toISOString();
      }

      return cleaned;
    });
  }

  @Get()
  async list() {
    const client = this.supabaseService.getClient();
    const primary = await client
      .from(this.primaryTable)
      .select("*")
      .order("name", { ascending: true });

    if (!primary.error) {
      return primary.data ?? [];
    }

    const fallback = await client
      .from(this.fallbackTable)
      .select("*")
      .eq("is_active", true)
      .order("name", { ascending: true });

    if (fallback.error) throw fallback.error;
    return fallback.data ?? [];
  }

  @Post("sync")
  async sync(@Body("items") items: Array<Record<string, any>>) {
    if (!Array.isArray(items)) {
      throw new BadRequestException("items must be an array");
    }
    if (items.length === 0) return [];

    const cleanedItems = this.cleanItems(items);
    const client = this.supabaseService.getClient();
    const primary = await client
      .from(this.primaryTable)
      .upsert(cleanedItems)
      .select();

    if (!primary.error) {
      return primary.data ?? [];
    }

    const fallbackItems = items.map((item) => {
      const cleaned = { ...item };
      if (typeof cleaned.is_active === "undefined") cleaned.is_active = true;
      return cleaned;
    });

    const fallback = await client
      .from(this.fallbackTable)
      .upsert(fallbackItems)
      .select();

    if (fallback.error) throw fallback.error;
    return fallback.data ?? [];
  }
}
