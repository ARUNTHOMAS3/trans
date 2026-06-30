import { SupabaseClient } from "@supabase/supabase-js";

export async function updatePurchaseOrderStatus(
  client: SupabaseClient,
  purchaseOrderId: string,
  entityId: string,
) {
  // 1. Get PO items to calculate expected total (quantity - cancelled_quantity)
  const { data: po, error: poError } = await client
    .from("purchase_orders")
    .select("status, order_number")
    .eq("id", purchaseOrderId)
    .eq("entity_id", entityId)
    .single();

  if (poError || !po) return;

  const { data: poItems, error: poItemsError } = await client
    .from("purchase_order_items")
    .select("quantity, cancelled_quantity, is_header, product_id")
    .eq("purchase_order_id", purchaseOrderId)
    .eq("entity_id", entityId);

  if (poItemsError || !poItems) return;

  let originalTotal = 0;
  let expectedTotal = 0;
  for (const item of poItems) {
    if (item.is_header) continue;
    const qty = parseFloat(item.quantity?.toString() ?? "0");
    const cancelled = parseFloat(item.cancelled_quantity?.toString() ?? "0");
    originalTotal += qty;
    expectedTotal += qty - cancelled;
  }

  // 2. Get all receive items for all "received" or "intransit" purchase receives of this PO
  const { data: receives, error: receivesError } = await client
    .from("purchase_receives")
    .select("id, status")
    .eq("purchase_order_id", purchaseOrderId)
    .eq("entity_id", entityId)
    .eq("is_delete", false)
    .in("status", ["received", "intransit"]);

  const poReceiveItemIds: string[] = [];
  let totalReceived = 0;
  if (!receivesError && receives) {
    for (const r of receives) {
      // Get receive items
      const { data: priItems } = await client
        .from("purchase_receive_items")
        .select("id, received")
        .eq("purchase_receive_id", r.id)
        .eq("entity_id", entityId);

      for (const pri of priItems ?? []) {
        if (pri.id) poReceiveItemIds.push(pri.id);
        // Check if there are batches
        const { data: pribItems } = await client
          .from("purchase_receive_item_batches")
          .select("quantity")
          .eq("purchase_receive_item_id", pri.id)
          .eq("entity_id", entityId);

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
  const { data: bills, error: billsError } = await client
    .from("bills")
    .select("id, order_number")
    .eq("entity_id", entityId)
    .eq("is_delete", false)
    .neq("status", "void");

  if (!billsError && bills) {
    const poNumNormalized = po.order_number.trim().toLowerCase();
    for (const b of bills) {
      const orderNumStr = (b.order_number ?? "").toString().toLowerCase();
      const orderNums = orderNumStr.split(",").map(x => x.trim());
      if (orderNums.includes(poNumNormalized)) {
        const isMultiPo = orderNumStr.includes(",");
        const { data: billItems } = await client
          .from("bill_items")
          .select("quantity, purchase_receive_item_id")
          .eq("bill_id", b.id);
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
  const isDraft = ["draft", "pending", "approved"].includes(po.status.toLowerCase());
  if (isDraft) {
    newStatus = po.status;
  } else {
    const isClosed = expectedTotal === 0 || (expectedTotal > 0 && totalBilled >= expectedTotal - 0.0001);
    newStatus = isClosed ? "Closed" : "Issued";
  }

  // 4. Update the PO status in DB
  await client
    .from("purchase_orders")
    .update({ status: newStatus })
    .eq("id", purchaseOrderId)
    .eq("entity_id", entityId);
}

export async function updatePurchaseOrderStatusByOrderNumber(
  client: SupabaseClient,
  orderNumber: string,
  entityId: string,
) {
  if (!orderNumber) return;
  const parts = orderNumber
    .split(",")
    .map((p) => p.trim())
    .filter((p) => p.length > 0);

  for (const part of parts) {
    const { data: po } = await client
      .from("purchase_orders")
      .select("id")
      .eq("order_number", part)
      .eq("entity_id", entityId)
      .maybeSingle();

    if (po && po.id) {
      await updatePurchaseOrderStatus(client, po.id, entityId);
    }
  }
}
