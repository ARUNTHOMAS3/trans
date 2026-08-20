import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
} from "@nestjs/common";
import * as crypto from "crypto";
import { SupabaseService } from "../supabase/supabase.service";
import { db, client } from "../../db/db";
import { shipmentPreferences } from "../../db/schema";
import { eq } from "drizzle-orm";

@Controller("shipment-preferences")
export class ShipmentPreferencesController {
  constructor(private readonly supabaseService: SupabaseService) {}

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
    try {
      const carriers = await client.unsafe(
        `SELECT * FROM carrier ORDER BY name ASC`,
      );
      if (carriers && carriers.length > 0) return carriers;
    } catch {
      // Fallback if carrier table doesn't exist
    }

    try {
      const prefs = await db
        .select()
        .from(shipmentPreferences)
        .where(eq(shipmentPreferences.isActive, true));

      return prefs.map((p) => ({
        id: p.id,
        name: p.name,
        created_at: p.createdAt,
        is_active: p.isActive,
      }));
    } catch (err) {
      console.error("[ShipmentPreferencesController] list error:", err);
      return [];
    }
  }

  @Post("sync")
  async sync(@Body("items") items: Array<Record<string, any>>) {
    if (!Array.isArray(items)) {
      throw new BadRequestException("items must be an array");
    }
    if (items.length === 0) return [];

    const cleanedItems = this.cleanItems(items);

    try {
      const synced = await client.unsafe(
        `INSERT INTO carrier (id, name, created_at)
         SELECT id, name, created_at FROM json_populate_recordset(null::carrier, $1::json)
         ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name
         RETURNING *`,
        [JSON.stringify(cleanedItems)],
      );
      if (synced && synced.length > 0) return synced;
    } catch {
      // Fallback to shipment_preferences
    }

    const fallbackItems = items.map((item) => ({
      name: item.name,
      isActive: item.is_active ?? true,
    }));

    try {
      const results = [];
      for (const item of fallbackItems) {
        const [inserted] = await db
          .insert(shipmentPreferences)
          .values(item)
          .returning();
        results.push({
          id: inserted.id,
          name: inserted.name,
          is_active: inserted.isActive,
        });
      }
      return results;
    } catch (err) {
      console.error("[ShipmentPreferencesController] sync error:", err);
      throw err;
    }
  }
}
