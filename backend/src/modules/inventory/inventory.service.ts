import { Injectable, Logger } from "@nestjs/common";
import { db } from "../../db/db";
import { outletInventory, product } from "../../db/schema";
import { eq, and, asc, desc, sql } from "drizzle-orm";

export enum InventoryValuationMethod {
  FIFO = "FIFO",
  LIFO = "LIFO",
  FEFO = "FEFO",
  WeightedAverage = "Weighted Average",
}

@Injectable()
export class InventoryService {
  private readonly logger = new Logger(InventoryService.name);

  /**
   * Sorting Logic for Inventory Dispatch
   * FIFO: ORDER BY received_date ASC (using lastStockUpdate as proxy or createdAt in batches)
   * LIFO: ORDER BY received_date DESC
   * FEFO: ORDER BY expiration_date ASC
   */
  async getAvailableBatches(
    productId: string,
    outletId: string,
    valuationMethod: string,
    requiredQty?: number,
  ) {
    let orderByClause: any;

    switch (valuationMethod) {
      case InventoryValuationMethod.FEFO:
        // Mandatory for perishables, pharmaceuticals. Expiry first.
        orderByClause = asc(outletInventory.expiryDate);
        break;
      case InventoryValuationMethod.LIFO:
        // Newest items first (received last).
        orderByClause = desc(outletInventory.lastStockUpdate);
        break;
      case InventoryValuationMethod.FIFO:
      default:
        // Oldest items first (received first).
        orderByClause = asc(outletInventory.lastStockUpdate);
        break;
    }

    const availableBatches = await db
      .select()
      .from(outletInventory)
      .where(
        and(
          eq(outletInventory.productId, productId),
          eq(outletInventory.outletId, outletId),
          sql`${outletInventory.currentStock} > 0`,
        ),
      )
      .orderBy(orderByClause);

    if (requiredQty) {
      // Logic to pick batches until required quantity is met
      let fulfilled = 0;
      const pickedBatches = [];

      for (const batch of availableBatches) {
        if (fulfilled >= requiredQty) break;
        const available = batch.currentStock;
        const toTake = Math.min(available, requiredQty - fulfilled);
        pickedBatches.push({ ...batch, takeQty: toTake });
        fulfilled += toTake;
      }
      return pickedBatches;
    }

    return availableBatches;
  }

  /**
   * Weighted Average Cost (WAC) Math Logic
   * New Average Cost = (Total Value of Existing Stock + Total Value of New Stock) / (Total Existing Qty + New Qty)
   */
  calculateWeightedAverageCost(
    existingQty: number,
    existingAvgCost: number,
    newQty: number,
    newUnitCost: number,
  ): number {
    const totalExistingValue = existingQty * existingAvgCost;
    const totalNewValue = newQty * newUnitCost;
    const totalQty = existingQty + newQty;

    if (totalQty === 0) return 0;

    const newAvgCost = (totalExistingValue + totalNewValue) / totalQty;
    return parseFloat(newAvgCost.toFixed(2));
  }

  /**
   * Update product average cost (WAC)
   */
  async updateProductWAC(
    productId: string,
    newQty: number,
    newUnitCost: number,
  ) {
    const productData = await db.query.product.findFirst({
      where: eq(product.id, productId),
    });

    if (!productData) return;

    // We need current stock across all outlets for true WAC or per outlet?
    // Usually WAC is per organization/valuation entity.
    const inventory = await db
      .select({ totalStock: sql<number>`sum(${outletInventory.currentStock})` })
      .from(outletInventory)
      .where(eq(outletInventory.productId, productId));

    const currentStock = Number(inventory[0]?.totalStock || 0);
    const currentAvgCost = Number(productData.costPrice || 0);

    const updatedAvgCost = this.calculateWeightedAverageCost(
      currentStock,
      currentAvgCost,
      newQty,
      newUnitCost,
    );

    await db
      .update(product)
      .set({ costPrice: updatedAvgCost.toString() as any })
      .where(eq(product.id, productId));

    this.logger.log(`Updated WAC for product ${productId}: ${updatedAvgCost}`);
    return updatedAvgCost;
  }
}
