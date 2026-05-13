import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Patch,
  Body,
  Param,
  InternalServerErrorException,
} from "@nestjs/common";
import { SupabaseService } from "../../supabase/supabase.service";

const HEADER_FIELDS = [
  "name", "description", "currency", "pricing_scheme", "details",
  "round_off_preference", "status", "price_list_type", "percentage_type",
  "percentage_value", "discount_enabled", "transaction_type",
];

function buildPriceListResponse(header: any, items: any[]): any {
  const itemRates = (items ?? []).map((item) => ({
    id: item.id,
    item_id: item.product_id,
    item_name: item.products?.product_name ?? null,
    sku: item.products?.sku ?? null,
    sales_rate: item.products?.selling_price ?? null,
    custom_rate: item.custom_rate,
    discount_percentage: item.discount_percentage,
    volume_ranges: (item.price_list_volume_ranges ?? []).map((r: any) => ({
      id: r.id,
      start_quantity: r.start_quantity,
      end_quantity: r.end_quantity,
      custom_rate: r.rate,
    })),
  }));
  return { ...header, item_rates: itemRates };
}

@Controller("price-lists")
export class PriceListController {
  constructor(private readonly supabaseService: SupabaseService) {}

  @Get()
  async findAll() {
    try {
      const { data, error } = await this.supabaseService
        .getClient()
        .from("price_lists")
        .select("*")
        .order("created_at", { ascending: false });

      if (error) throw error;
      return { data };
    } catch (e) {
      throw new InternalServerErrorException(e.message);
    }
  }

  @Get(":id")
  async findOne(@Param("id") id: string) {
    try {
      const sb = this.supabaseService.getClient();

      const { data: header, error: hErr } = await sb
        .from("price_lists")
        .select("*")
        .eq("id", id)
        .single();
      if (hErr) throw hErr;

      const { data: items, error: iErr } = await sb
        .from("price_list_items")
        .select(`*, products(product_name, sku, selling_price), price_list_volume_ranges(*)`)
        .eq("price_list_id", id)
        .eq("is_active", true);
      if (iErr) throw iErr;

      return { data: buildPriceListResponse(header, items ?? []) };
    } catch (e) {
      throw new InternalServerErrorException(e.message);
    }
  }

  @Post()
  async create(@Body() body: any) {
    try {
      const headerPayload: any = {};
      for (const f of HEADER_FIELDS) {
        if (body[f] !== undefined) headerPayload[f] = body[f];
      }
      const { data, error } = await this.supabaseService
        .getClient()
        .from("price_lists")
        .insert(headerPayload)
        .select()
        .single();

      if (error) throw error;
      return { data };
    } catch (e) {
      throw new InternalServerErrorException(e.message);
    }
  }

  @Put(":id")
  async update(@Param("id") id: string, @Body() body: any) {
    try {
      console.log("[PriceList PUT] id:", id, "item_rates count:", (body.item_rates ?? []).length, "sample:", JSON.stringify((body.item_rates ?? []).slice(0, 1)));
      const sb = this.supabaseService.getClient();

      // 1. Update header fields only
      const headerPayload: any = { updated_at: new Date().toISOString() };
      for (const f of HEADER_FIELDS) {
        if (body[f] !== undefined) headerPayload[f] = body[f];
      }
      const { data: header, error: hErr } = await sb
        .from("price_lists")
        .update(headerPayload)
        .eq("id", id)
        .select()
        .single();
      if (hErr) throw hErr;

      // 2. Save item rates (select-then-insert-or-update, no unique constraint required)
      const itemRates: any[] = body.item_rates ?? [];
      for (const rate of itemRates) {
        if (!rate.item_id) continue;

        // Check if row already exists
        const { data: existing } = await sb
          .from("price_list_items")
          .select("id")
          .eq("price_list_id", id)
          .eq("product_id", rate.item_id)
          .maybeSingle();

        let pliId: string;
        if (existing) {
          // Update existing row
          const { error: upErr } = await sb
            .from("price_list_items")
            .update({
              custom_rate: rate.custom_rate ?? null,
              discount_percentage: rate.discount_percentage ?? null,
              updated_at: new Date().toISOString(),
            })
            .eq("id", existing.id);
          if (upErr) throw upErr;
          pliId = existing.id;
        } else {
          // Insert new row
          const { data: ins, error: insErr } = await sb
            .from("price_list_items")
            .insert({
              price_list_id: id,
              product_id: rate.item_id,
              custom_rate: rate.custom_rate ?? null,
              discount_percentage: rate.discount_percentage ?? null,
            })
            .select("id")
            .single();
          if (insErr) throw insErr;
          pliId = ins.id;
        }

        // 3. Replace volume ranges
        const volRanges: any[] = rate.volume_ranges ?? [];
        await sb.from("price_list_volume_ranges").delete().eq("price_list_item_id", pliId);
        if (volRanges.length > 0) {
          const rangeRows = volRanges.map((r: any) => ({
            price_list_item_id: pliId,
            start_quantity: r.start_quantity ?? 1,
            end_quantity: r.end_quantity ?? null,
            rate: r.custom_rate ?? 0,
          }));
          const { error: rErr } = await sb.from("price_list_volume_ranges").insert(rangeRows);
          if (rErr) throw rErr;
        }
      }

      // 4. Return full enriched response
      const { data: items } = await sb
        .from("price_list_items")
        .select(`*, products(product_name, sku, selling_price), price_list_volume_ranges(*)`)
        .eq("price_list_id", id)
        .eq("is_active", true);

      return { data: buildPriceListResponse(header, items ?? []) };
    } catch (e) {
      throw new InternalServerErrorException(e.message);
    }
  }

  @Delete(":id")
  async remove(@Param("id") id: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from("price_lists")
      .delete()
      .eq("id", id);

    if (error) throw error;
    return { success: true };
  }

  @Patch(":id/deactivate")
  async deactivate(@Param("id") id: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("price_lists")
      .update({
        status: "inactive",
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;
    return { data };
  }

  @Get("product/:productId")
  async findByProduct(@Param("productId") productId: string) {
    try {
      const { data, error } = await this.supabaseService
        .getClient()
        .from("price_list_items")
        .select(
          `
          id,
          custom_rate,
          discount_percentage,
          price_lists (
            id,
            name,
            currency,
            transaction_type,
            pricing_scheme
          )
        `,
        )
        .eq("product_id", productId);

      if (error) {
        console.error("Supabase Error (findByProduct):", error);
        throw error;
      }
      return { data };
    } catch (e) {
      console.error("Exception in findByProduct:", e);
      throw new InternalServerErrorException(e.message);
    }
  }

  @Post("associate")
  async associate(
    @Body()
    body: {
      product_id: string;
      price_list_id: string;
      custom_rate?: number;
      discount_percentage?: number;
    },
  ) {
    try {
      const { data, error } = await this.supabaseService
        .getClient()
        .from("price_list_items")
        .insert(body)
        .select()
        .single();

      if (error) throw error;
      return { data };
    } catch (e) {
      throw new InternalServerErrorException(e.message);
    }
  }
}
