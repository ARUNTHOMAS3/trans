import { client as dbClient } from "../../../../db/db";

export async function updatePurchaseOrderStatus(
  clientInstance: any,
  purchaseOrderId: string,
  entityId: string,
) {
  // 1. Get PO items to calculate expected total (quantity - cancelled_quantity)
  const poRows = await dbClient.unsafe(
    `SELECT status, order_number FROM purchase_orders WHERE id = $1 AND entity_id = $2 LIMIT 1`,
    [purchaseOrderId, entityId],
  );

  const po = poRows[0];
  if (!po) return;

  const poItems = await dbClient.unsafe(
    `SELECT quantity, cancelled_quantity, is_header, product_id FROM purchase_order_items WHERE purchase_order_id = $1 AND entity_id = $2`,
    [purchaseOrderId, entityId],
  );

  let originalTotal = 0;
  let expectedTotal = 0;
  for (const item of poItems ?? []) {
    if (item.is_header) continue;
    const qty = parseFloat(item.quantity?.toString() ?? "0");
    const cancelled = parseFloat(item.cancelled_quantity?.toString() ?? "0");
    originalTotal += qty;
    expectedTotal += qty - cancelled;
  }

  // 2. Get all receive items for all "received" or "intransit" purchase receives of this PO
  const receives = await dbClient.unsafe(
    `SELECT id, status FROM purchase_receives WHERE purchase_order_id = $1 AND entity_id = $2 AND is_delete = false AND status = ANY($3)`,
    [purchaseOrderId, entityId, ["received", "intransit"]],
  );

  const poReceiveItemIds: string[] = [];
  let totalReceived = 0;
  if (receives && receives.length > 0) {
    for (const r of receives) {
      const priItems = await dbClient.unsafe(
        `SELECT id, received FROM purchase_receive_items WHERE purchase_receive_id = $1 AND entity_id = $2`,
        [r.id, entityId],
      );

      for (const pri of priItems ?? []) {
        if (pri.id) poReceiveItemIds.push(pri.id);
        const pribItems = await dbClient.unsafe(
          `SELECT quantity FROM purchase_receive_item_batches WHERE purchase_receive_item_id = $1 AND entity_id = $2`,
          [pri.id, entityId],
        );

        if (pribItems && pribItems.length > 0) {
          for (const prib of pribItems) {
            totalReceived += parseFloat(prib.quantity?.toString() ?? "0");
          }
        } else {
          totalReceived += parseFloat(pri.received?.toString() ?? "0");
        }
      }
    }
  }

  // 3. Get all bill items for all non-deleted, non-void bills of this PO
  let totalBilled = 0;
  const bills = await dbClient.unsafe(
    `SELECT id, order_number FROM bills WHERE entity_id = $1 AND is_delete = false AND status != 'void'`,
    [entityId],
  );

  if (bills && bills.length > 0) {
    const poNumNormalized = (po.order_number || "").trim().toLowerCase();
    for (const b of bills) {
      const orderNumStr = (b.order_number ?? "").toString().toLowerCase();
      const orderNums = orderNumStr.split(",").map((x: string) => x.trim());
      if (orderNums.includes(poNumNormalized)) {
        const isMultiPo = orderNumStr.includes(",");
        const billItems = await dbClient.unsafe(
          `SELECT quantity, purchase_receive_item_id FROM bill_items WHERE bill_id = $1`,
          [b.id],
        );

        for (const bi of billItems ?? []) {
          const prItemId = bi.purchase_receive_item_id;
          if (prItemId) {
            if (poReceiveItemIds.includes(prItemId)) {
              totalBilled += parseFloat(bi.quantity?.toString() ?? "0");
            }
          } else if (!isMultiPo) {
            totalBilled += parseFloat(bi.quantity?.toString() ?? "0");
          }
        }
      }
    }
  }

  // Determine status
  let newStatus = po.status;
  const isDraft = ["draft", "pending", "approved"].includes((po.status || "").toLowerCase());
  if (isDraft) {
    newStatus = po.status;
  } else {
    const isClosed = expectedTotal === 0 || (expectedTotal > 0 && totalBilled >= expectedTotal - 0.0001);
    newStatus = isClosed ? "Closed" : "Issued";
  }

  // 4. Update the PO status in DB
  await dbClient.unsafe(
    `UPDATE purchase_orders SET status = $1 WHERE id = $2 AND entity_id = $3`,
    [newStatus, purchaseOrderId, entityId],
  );
}

export async function updatePurchaseOrderStatusByOrderNumber(
  clientInstance: any,
  orderNumber: string,
  entityId: string,
) {
  if (!orderNumber) return;
  const parts = orderNumber
    .split(",")
    .map((p) => p.trim())
    .filter((p) => p.length > 0);

  for (const part of parts) {
    const poRows = await dbClient.unsafe(
      `SELECT id FROM purchase_orders WHERE order_number = $1 AND entity_id = $2 LIMIT 1`,
      [part, entityId],
    );

    if (poRows[0]?.id) {
      await updatePurchaseOrderStatus(clientInstance, poRows[0].id, entityId);
    }
  }
}
