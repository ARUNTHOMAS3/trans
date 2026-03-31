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

@Controller("price-lists")
export class PriceListController {
  constructor(private readonly supabaseService: SupabaseService) {}

  @Get()
  async findAll() {
    try {
      console.log("Fetching price lists...");
      const { data, error } = await this.supabaseService
        .getClient()
        .from("price_lists")
        .select("*")
        .order("created_at", { ascending: false });

      if (error) {
        console.error("Supabase Error:", error);
        throw error;
      }
      return { data };
    } catch (e) {
      console.error("Exception in findAll:", e);
      throw new InternalServerErrorException(e.message);
    }
  }

  @Get(":id")
  async findOne(@Param("id") id: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("price_lists")
      .select("*")
      .eq("id", id)
      .single();

    if (error) throw error;
    return { data };
  }

  @Post()
  async create(@Body() body: any) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("price_lists")
      .insert(body)
      .select()
      .single();

    if (error) throw error;
    return { data };
  }

  @Put(":id")
  async update(@Param("id") id: string, @Body() body: any) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("price_lists")
      .update({
        ...body,
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;
    return { data };
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
