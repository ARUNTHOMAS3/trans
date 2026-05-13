import { Injectable, Logger } from "@nestjs/common";
import { db } from "../../../db/db";
import { hsnSacCodes } from "../../../db/schema";
import { ilike, or, and, eq } from "drizzle-orm";

@Injectable()
export class HsnSacService {
  private readonly logger = new Logger(HsnSacService.name);

  async searchHsnSac(query: string, type: "HSN" | "SAC") {
    try {
      this.logger.log(`Searching ${type} for query: ${query}`);

      const results = await db
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
        `Found ${results.length} results for ${type} query: ${query}`,
      );

      return results.map((item) => ({
        code: item.code,
        description: item.description,
      }));
    } catch (error) {
      this.logger.error(
        `Error searching ${type} via Drizzle: ${error.message}`,
      );
      return [];
    }
  }
}
