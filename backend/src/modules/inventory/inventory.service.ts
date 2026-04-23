import { Injectable, Logger } from "@nestjs/common";
import { db } from "../../db/db";
import { branchInventory, product } from "../../db/schema";
import { eq, and, asc, desc, sql } from "drizzle-orm";
import { TenantContext } from "../../common/middleware/tenant.middleware";

export enum InventoryValuationMethod {
  FIFO = "FIFO",
  LIFO = "LIFO",
  FEFO = "FEFO",
  WeightedAverage = "Weighted Average",
}

@Injectable()
export class InventoryService {
  private readonly logger = new Logger(InventoryService.name);

  private getEntityFilter(tenant: TenantContext) {
    return eq(branchInventory.entityId, tenant.entityId as string);
  }

  /**
   * Sorting Logic for Inventory Dispatch
   */
  async getAvailableBatches(
    productId: string,
    _branchId: string,
    valuationMethod: string,
    tenant: TenantContext,
    requiredQty?: number,
  ) {
    let orderByClause: any;

    switch (valuationMethod) {
      case InventoryValuationMethod.FEFO:
        orderByClause = asc(branchInventory.expiryDate);
        break;
      case InventoryValuationMethod.LIFO:
        orderByClause = desc(branchInventory.lastStockUpdate);
        break;
      case InventoryValuationMethod.FIFO:
      default:
        orderByClause = asc(branchInventory.lastStockUpdate);
        break;
    }

    const availableBatches = await db
      .select()
      .from(branchInventory)
      .where(
        and(
          eq(branchInventory.productId, productId),
          this.getEntityFilter(tenant),
          sql`${branchInventory.currentStock} > 0`,
        ),
      )
      .orderBy(orderByClause);

    if (requiredQty) {
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
    tenant: TenantContext,
  ) {
    const productData = await db.query.product.findFirst({
      where: eq(product.id, productId),
    });

    if (!productData) return;

    const inventory = await db
      .select({ totalStock: sql<number>`sum(${branchInventory.currentStock})` })
      .from(branchInventory)
      .where(
        and(
          eq(branchInventory.productId, productId),
          this.getEntityFilter(tenant),
        ),
      );

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
