jest.mock("../../db/db", () => ({ db: {} }));

import { BadRequestException } from "@nestjs/common";
import { TransactionLockingService } from "./transaction-locking.service";

describe("TransactionLockingService negative stock policy", () => {
  const tenant = {
    entityId: "66d79887-be98-40ab-ac40-9e0a008f9d8a",
    orgId: "00000000-0000-0000-0000-000000000002",
  } as any;

  it("blocks locking when Restrict is active and accounting stock is negative", async () => {
    const stockQuery = {
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      lt: jest.fn().mockReturnThis(),
      limit: jest.fn().mockResolvedValue({
        data: [{ product_id: "product", stock_on_hand: "-1" }],
        error: null,
      }),
    };
    const client = { from: jest.fn().mockReturnValue(stockQuery) };
    const service = new TransactionLockingService({
      getClient: () => client,
    } as any);
    jest
      .spyOn(service, "getNegativeStockPolicy")
      .mockResolvedValue({ mode: "restrict" });

    await expect(
      (service as any).assertNegativeStockPolicyAllowsLock(tenant),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it("allows locking without a stock query when Allow is active", async () => {
    const client = { from: jest.fn() };
    const service = new TransactionLockingService({
      getClient: () => client,
    } as any);
    jest
      .spyOn(service, "getNegativeStockPolicy")
      .mockResolvedValue({ mode: "allow" });

    await expect(
      (service as any).assertNegativeStockPolicyAllowsLock(tenant),
    ).resolves.toBeUndefined();
    expect(client.from).not.toHaveBeenCalled();
  });
});
