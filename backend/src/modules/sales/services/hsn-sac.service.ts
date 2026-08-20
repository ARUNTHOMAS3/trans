import { Injectable, Logger } from "@nestjs/common";
import { db, client } from "../../../db/db";
import { hsnSacCodes, product } from "../../../db/schema";
import { ilike, or, and, eq, isNotNull } from "drizzle-orm";
import { SupabaseService } from "../../supabase/supabase.service";

@Injectable()
export class HsnSacService {
  private readonly logger = new Logger(HsnSacService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  private async searchHsnSacFromClient(query: string, type: "HSN" | "SAC") {
    try {
      const data = await client.unsafe(
        `SELECT code, description FROM hsn_sac_codes
         WHERE type = $1 AND (code ILIKE $2 OR description ILIKE $2)
         LIMIT 50`,
        [type, `%${query}%`],
      );

      return (data ?? []).map((row: any) => ({
        code: row.code,
        description: row.description,
      }));
    } catch (error) {
      throw new Error((error as Error).message);
    }
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
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error
          ? error.message
          : typeof error === "string"
          ? error
          : JSON.stringify(error);

      this.logger.error(`Error searching ${type} via Drizzle: ${errorMessage}`);

      try {
        const masterFallback = await this.searchHsnSacFromClient(query, type);
        if (masterFallback.length > 0) {
          return masterFallback;
        }
      } catch (clientError: unknown) {
        this.logger.error(
          `Fallback search error: ${clientError instanceof Error ? clientError.message : String(clientError)}`,
        );
      }

      if (type === "HSN") {
        try {
          return await this.searchHsnFromProducts(query);
        } catch {
          // ignore
        }
      }

      return [];
    }
  }
}
