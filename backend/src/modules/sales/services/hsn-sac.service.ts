import { Injectable, Logger } from "@nestjs/common";
import { db } from "../../../db/db";
import { hsnSacCodes, product } from "../../../db/schema";
import { ilike, or, and, eq, isNotNull } from "drizzle-orm";
import { SupabaseService } from "../../supabase/supabase.service";

@Injectable()
export class HsnSacService {
  private readonly logger = new Logger(HsnSacService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  private async searchHsnSacFromSupabase(query: string, type: "HSN" | "SAC") {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("hsn_sac_codes")
      .select("code,description")
      .eq("type", type)
      .or(`code.ilike.%${query}%,description.ilike.%${query}%`)
      .limit(50);

    if (error) {
      throw new Error(error.message);
    }

    return (data ?? []).map((row) => ({
      code: row.code,
      description: row.description,
    }));
  }

  private async searchHsnFromProducts(query: string) {
    const productMatches = await db
      .select({
        code: product.hsnCode,
        description: product.productName,
      })
      .from(product)
      .where(
        and(
          isNotNull(product.hsnCode),
          or(
            ilike(product.hsnCode, `%${query}%`),
            ilike(product.productName, `%${query}%`),
          ),
        ),
      )
      .limit(100);

    return Array.from(
      new Map(
        productMatches
          .filter((row) => (row.code ?? "").trim().length > 0)
          .map((row) => [
            (row.code ?? "").trim(),
            {
              code: (row.code ?? "").trim(),
              description: row.description ?? "",
            },
          ]),
      ).values(),
    ).slice(0, 50);
  }

  private async searchHsnFromProductsSupabase(query: string) {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("products")
      .select("hsn_code,product_name")
      .not("hsn_code", "is", null)
      .or(`hsn_code.ilike.%${query}%,product_name.ilike.%${query}%`)
      .limit(100);

    if (error) {
      throw new Error(error.message);
    }

    return Array.from(
      new Map(
        (data ?? [])
          .filter((row) => (row.hsn_code ?? "").trim().length > 0)
          .map((row) => [
            (row.hsn_code ?? "").trim(),
            {
              code: (row.hsn_code ?? "").trim(),
              description: row.product_name ?? "",
            },
          ]),
      ).values(),
    ).slice(0, 50);
  }

  async searchHsnSac(query: string, type: "HSN" | "SAC") {
    try {
      this.logger.log(
        `[HSN_DEBUG] phase=start type=${type} query="${query}"`,
      );

      const masterResults = await db
        .select()
        .from(hsnSacCodes)
        .where(
          and(
            eq(hsnSacCodes.type, type),
            or(
              ilike(hsnSacCodes.code, `%${query}%`),
              ilike(hsnSacCodes.description, `%${query}%`),
            ),
          ),
        )
        .limit(50);

      this.logger.log(
        `[HSN_DEBUG] phase=master_result type=${type} query="${query}" master_count=${masterResults.length}`,
      );

      if (masterResults.length > 0) {
        this.logger.log(
          `Found ${masterResults.length} master results for ${type} query: ${query}`,
        );

        return masterResults.map((item) => ({
          code: item.code,
          description: item.description,
        }));
      }

      if (type === "HSN") {
        const deduped = await this.searchHsnFromProducts(query);

        this.logger.log(
          `Master empty; found ${deduped.length} product fallback results for HSN query: ${query}`,
        );
        this.logger.log(
          `[HSN_DEBUG] phase=fallback_empty_master type=${type} query="${query}" fallback_count=${deduped.length}`,
        );
        return deduped;
      }

      this.logger.log(`Found 0 results for ${type} query: ${query}`);
      return [];
    } catch (error) {
      this.logger.error(`Error searching ${type} via Drizzle: ${error.message}`);
      this.logger.error(
        `[HSN_DEBUG] phase=master_error type=${type} query="${query}" error="${error.message}"`,
      );

      try {
        const masterFallback = await this.searchHsnSacFromSupabase(query, type);
        this.logger.warn(
          `[HSN_DEBUG] phase=supabase_master_fallback type=${type} query="${query}" fallback_count=${masterFallback.length}`,
        );
        if (masterFallback.length > 0) {
          return masterFallback;
        }
      } catch (supabaseError) {
        this.logger.error(
          `[HSN_DEBUG] phase=supabase_master_fallback_error type=${type} query="${query}" error="${supabaseError.message}"`,
        );
      }

      if (type === "HSN") {
        try {
          const deduped = await this.searchHsnFromProducts(query);
          this.logger.warn(
            `Recovered HSN search via product fallback after master error; results=${deduped.length}`,
          );
          this.logger.warn(
            `[HSN_DEBUG] phase=fallback_after_error type=${type} query="${query}" fallback_count=${deduped.length}`,
          );
          return deduped;
        } catch (fallbackError) {
          try {
            const supabaseDeduped = await this.searchHsnFromProductsSupabase(query);
            this.logger.warn(
              `[HSN_DEBUG] phase=supabase_product_fallback type=${type} query="${query}" fallback_count=${supabaseDeduped.length}`,
            );
            return supabaseDeduped;
          } catch (supabaseFallbackError) {
            this.logger.error(
              `[HSN_DEBUG] phase=supabase_product_fallback_error type=${type} query="${query}" error="${supabaseFallbackError.message}"`,
            );
          }

          this.logger.error(
            `HSN product fallback also failed: ${fallbackError.message}`,
          );
          this.logger.error(
            `[HSN_DEBUG] phase=fallback_error type=${type} query="${query}" error="${fallbackError.message}"`,
          );
        }
      }

      return [];
    }
  }
}
