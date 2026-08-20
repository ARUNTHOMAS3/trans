import { Injectable, NotFoundException } from '@nestjs/common';
import { TenantContext } from '../../../../common/middleware/tenant.middleware';
import { SupabaseService } from '../../../supabase/supabase.service';
import { CreateSalesReturnDto } from '../dto/create-sales-return.dto';
import { UpdateSalesReturnDto } from '../dto/update-sales-return.dto';
import { CreateSalesReturnReceiveDto } from '../dto/create-sales-return-receive.dto';
import { client } from '../../../../db/db';

@Injectable()
export class SalesReturnsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private escapeRegExp(value: string) {
    return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  private async getNextRmaNumber(tenant: TenantContext, prefix = 'RMA-') {
    const safePrefix = prefix || 'RMA-';
    try {
      const data = await client.unsafe(
        `SELECT rma_number FROM sales_returns WHERE entity_id = $1 ORDER BY rma_number DESC LIMIT 1000`,
        [tenant.entityId],
      );

      let maxNumber = 0;
      for (const row of data ?? []) {
        if (!row.rma_number || !row.rma_number.startsWith(safePrefix)) continue;
        const match = row.rma_number.match(/(\d+)$/);
        if (match) {
          const num = parseInt(match[1], 10);
          if (num > maxNumber) maxNumber = num;
        }
      }

      return {
        prefix: safePrefix,
        nextNumber: maxNumber + 1,
        formatted: `${safePrefix}${(maxNumber + 1).toString().padStart(5, '0')}`,
      };
    } catch (error) {
      throw new Error(`Failed to generate RMA number: ${(error as Error).message}`);
    }
  }

  async getNextNumber(tenant: TenantContext, prefix?: string) {
    return this.getNextRmaNumber(tenant, prefix ?? 'RMA-');
  }

  private async insertItems(returnId: string, items: CreateSalesReturnDto['items'], tenant: TenantContext) {
    if (!items?.length) return;

    for (const item of items) {
      await client.unsafe(
        `INSERT INTO sales_return_items (sales_return_id, product_id, sales_invoice_item_id, invoiced_qty, already_returned_qty, return_qty, receivable_qty, credit_only_qty, remarks)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          returnId,
          item.product_id,
          item.sales_invoice_item_id ?? null,
          item.invoiced_qty ?? 0,
          item.already_returned_qty ?? 0,
          item.return_qty ?? 0,
          item.receivable_qty ?? item.return_qty ?? 0,
          item.credit_only_qty ?? 0,
          item.remarks ?? null,
        ],
      );
    }
  }

  private async deleteReceiveCascade(receiveId: string) {
    const receiveItems = await client.unsafe(
      `SELECT id FROM sales_return_receive_items WHERE sales_return_receive_id = $1`,
      [receiveId],
    );

    const receiveItemIds = (receiveItems ?? [])
      .map((row: any) => row.id as string)
      .filter((id: string) => !!id);

    if (receiveItemIds.length > 0) {
      await client.unsafe(
        `DELETE FROM sales_return_receive_batches WHERE sales_return_receive_item_id = ANY($1)`,
        [receiveItemIds],
      );
    }

    await client.unsafe(
      `DELETE FROM sales_return_receive_items WHERE sales_return_receive_id = $1`,
      [receiveId],
    );

    await client.unsafe(
      `DELETE FROM sales_return_receives WHERE id = $1`,
      [receiveId],
    );
  }

  async findAll(tenant: TenantContext, page = 1, limit = 100, search?: string, status?: string) {
    const offset = (page - 1) * limit;

    let sqlQuery = `SELECT * FROM sales_returns WHERE entity_id = $1`;
    let countQuery = `SELECT COUNT(*)::int as count FROM sales_returns WHERE entity_id = $1`;
    const params: any[] = [tenant.entityId];

    if (search) {
      params.push(`%${search}%`);
      const sIdx = params.length;
      sqlQuery += ` AND (rma_number ILIKE $${sIdx} OR reference_number ILIKE $${sIdx})`;
      countQuery += ` AND (rma_number ILIKE $${sIdx} OR reference_number ILIKE $${sIdx})`;
    }
    if (status && status.toLowerCase() !== 'all') {
      params.push(status.toLowerCase());
      const stIdx = params.length;
      sqlQuery += ` AND status = $${stIdx}`;
      countQuery += ` AND status = $${stIdx}`;
    }

    sqlQuery += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    const [data, countRes] = await Promise.all([
      client.unsafe(sqlQuery, [...params, limit, offset]),
      client.unsafe(countQuery, params),
    ]);

    const totalCount = countRes[0]?.count ?? 0;

    for (const row of data ?? []) {
      const items = await client.unsafe(
        `SELECT * FROM sales_return_items WHERE sales_return_id = $1`,
        [row.id],
      );
      row.items = items ?? [];
    }

    return {
      data: data ?? [],
      meta: { total: totalCount, page, limit, totalPages: Math.ceil(totalCount / limit) },
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const rows = await client.unsafe(
      `SELECT * FROM sales_returns WHERE id = $1 AND entity_id = $2 LIMIT 1`,
      [id, tenant.entityId],
    );

    const data = rows[0];
    if (!data) throw new NotFoundException(`Sales Return ${id} not found`);

    const items = await client.unsafe(
      `SELECT * FROM sales_return_items WHERE sales_return_id = $1`,
      [id],
    );
    data.items = items ?? [];

    return data;
  }

  async create(dto: CreateSalesReturnDto, tenant: TenantContext) {
    const { items, ...headerData } = dto;

    const rows = await client.unsafe(
      `INSERT INTO sales_returns (entity_id, customer_id, rma_number, return_date, warehouse_id, reason, reference_number, contains_credit_only_goods, status, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [
        tenant.entityId,
        headerData.customer_id,
        headerData.rma_number,
        headerData.return_date,
        headerData.warehouse_id,
        headerData.reason ?? null,
        headerData.reference_number ?? null,
        headerData.contains_credit_only_goods ?? false,
        headerData.status ?? 'draft',
        headerData.notes ?? null,
      ],
    );

    const created = rows[0];
    if (!created) throw new Error("Failed to create sales return");

    await this.insertItems(created.id, items, tenant);
    return { ...created, items: [] };
  }

  async update(id: string, dto: UpdateSalesReturnDto, tenant: TenantContext) {
    const { items, ...headerData } = dto;

    if (Object.keys(headerData).length > 0) {
      await client.unsafe(
        `UPDATE sales_returns SET
           customer_id = COALESCE($1, customer_id),
           rma_number = COALESCE($2, rma_number),
           return_date = COALESCE($3, return_date),
           warehouse_id = COALESCE($4, warehouse_id),
           reason = COALESCE($5, reason),
           reference_number = COALESCE($6, reference_number),
           contains_credit_only_goods = COALESCE($7, contains_credit_only_goods),
           status = COALESCE($8, status),
           notes = COALESCE($9, notes),
           updated_at = NOW()
         WHERE id = $10 AND entity_id = $11`,
        [
          headerData.customer_id ?? null,
          headerData.rma_number ?? null,
          headerData.return_date ?? null,
          headerData.warehouse_id ?? null,
          headerData.reason ?? null,
          headerData.reference_number ?? null,
          headerData.contains_credit_only_goods ?? null,
          headerData.status ?? null,
          headerData.notes ?? null,
          id,
          tenant.entityId,
        ],
      );
    }

    if (items) {
      await client.unsafe(`DELETE FROM sales_return_items WHERE sales_return_id = $1`, [id]);
      await this.insertItems(id, items, tenant);
    }

    return this.findOne(id, tenant);
  }

  async createReceive(salesReturnId: string, dto: CreateSalesReturnReceiveDto, tenant: TenantContext) {
    const hasBatches = (dto.items ?? []).some((item) => (item.batches?.length ?? 0) > 0);
    if (hasBatches && !dto.warehouse_id) {
      throw new Error('Warehouse is required to save receive batches.');
    }

    const existing = await client.unsafe(
      `SELECT id FROM sales_return_receives WHERE sales_return_id = $1 AND entity_id = $2`,
      [salesReturnId, tenant.entityId],
    );

    const receiveCount = (existing?.length ?? 0) + 1;
    const receiveNumber = `RR-${receiveCount.toString().padStart(5, '0')}`;

    const rows = await client.unsafe(
      `INSERT INTO sales_return_receives (sales_return_id, entity_id, receive_number, receive_date, warehouse_id, notes, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'received')
       RETURNING *`,
      [
        salesReturnId,
        tenant.entityId,
        receiveNumber,
        dto.receive_date,
        dto.warehouse_id ?? null,
        dto.notes ?? null,
      ],
    );

    const receive = rows[0];
    if (!receive) throw new Error("Failed to create receive");

    const receiveItemRecords: Array<{
      id: string;
      product_id: string;
      batches?: CreateSalesReturnReceiveDto['items'][number]['batches'];
    }> = [];

    for (const item of dto.items ?? []) {
      const itemRows = await client.unsafe(
        `INSERT INTO sales_return_receive_items (sales_return_receive_id, product_id, sales_return_item_id, receiving_qty, return_qty, already_received_qty, remarks)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING id, product_id`,
        [
          receive.id,
          item.product_id,
          item.sales_return_item_id ?? null,
          item.receiving_qty,
          item.return_qty ?? 0,
          item.already_received_qty ?? 0,
          item.remarks ?? null,
        ],
      );

      const receiveItem = itemRows[0];
      if (!receiveItem) throw new Error("Failed to insert receive items");

      receiveItemRecords.push({
        id: receiveItem.id,
        product_id: receiveItem.product_id,
        batches: item.batches,
      });
    }

    for (const [index, record] of receiveItemRecords.entries()) {
      const batches = dto.items?.[index]?.batches ?? [];
      if (!batches.length) continue;

      for (const batch of batches) {
        await client.unsafe(
          `INSERT INTO sales_return_receive_batches (sales_return_receive_item_id, batch_id, layer_id, warehouse_id, bin_id, quantity, foc_quantity, purchase_rate, mrp, expiry_date, manufacture_date, manufacture_batch_no)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
          [
            record.id,
            batch.batch_id,
            batch.layer_id ?? null,
            batch.warehouse_id ?? dto.warehouse_id ?? null,
            batch.bin_id,
            batch.quantity,
            batch.foc_quantity ?? 0,
            batch.purchase_rate ?? null,
            batch.mrp ?? null,
            batch.expiry_date ?? null,
            batch.manufacture_date ?? null,
            batch.manufacture_batch_no ?? null,
          ],
        );
      }
    }

    await client.unsafe(
      `UPDATE sales_returns SET status = 'received' WHERE id = $1 AND entity_id = $2`,
      [salesReturnId, tenant.entityId],
    );

    return { ...receive, items: dto.items ?? [] };
  }

  async getReceives(salesReturnId: string, tenant: TenantContext) {
    const receives = await client.unsafe(
      `SELECT * FROM sales_return_receives WHERE sales_return_id = $1 AND entity_id = $2 ORDER BY created_at DESC`,
      [salesReturnId, tenant.entityId],
    );

    for (const receive of receives ?? []) {
      const items = await client.unsafe(
        `SELECT * FROM sales_return_receive_items WHERE sales_return_receive_id = $1`,
        [receive.id],
      );
      receive.items = items ?? [];
    }

    return receives ?? [];
  }

  async remove(id: string, tenant: TenantContext) {
    const receives = await client.unsafe(
      `SELECT id FROM sales_return_receives WHERE sales_return_id = $1 AND entity_id = $2`,
      [id, tenant.entityId],
    );

    for (const receive of receives ?? []) {
      await this.deleteReceiveCascade(receive.id as string);
    }

    await client.unsafe(`DELETE FROM sales_return_items WHERE sales_return_id = $1`, [id]);
    await client.unsafe(
      `DELETE FROM sales_returns WHERE id = $1 AND entity_id = $2`,
      [id, tenant.entityId],
    );

    return { message: 'Sales return deleted successfully' };
  }

  async removeReceive(salesReturnId: string, receiveId: string, tenant: TenantContext) {
    const rows = await client.unsafe(
      `SELECT id, sales_return_id FROM sales_return_receives WHERE id = $1 AND sales_return_id = $2 AND entity_id = $3 LIMIT 1`,
      [receiveId, salesReturnId, tenant.entityId],
    );

    if (!rows[0]) {
      throw new NotFoundException(`Sales Return Receive ${receiveId} not found`);
    }

    await this.deleteReceiveCascade(receiveId);

    const remainingReceives = await client.unsafe(
      `SELECT id FROM sales_return_receives WHERE sales_return_id = $1 AND entity_id = $2`,
      [salesReturnId, tenant.entityId],
    );

    if ((remainingReceives ?? []).length === 0) {
      await client.unsafe(
        `UPDATE sales_returns SET status = 'approved' WHERE id = $1 AND entity_id = $2`,
        [salesReturnId, tenant.entityId],
      );
    }

    return { message: 'Sales return receive deleted successfully' };
  }
}
