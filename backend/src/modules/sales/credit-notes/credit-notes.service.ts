import { Injectable, InternalServerErrorException } from "@nestjs/common";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../supabase/supabase.service";
import { CreateCreditNoteDto } from "./dto/create-credit-note.dto";
import { client } from "../../../db/db";

export { CreateCreditNoteDto };

@Injectable()
export class CreditNotesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(
    tenant: TenantContext,
    page = 1,
    limit = 100,
    search?: string,
    status?: string,
  ) {
    const offset = (page - 1) * limit;

    let sqlQuery = `SELECT * FROM credit_notes WHERE entity_id = $1`;
    let countQuery = `SELECT COUNT(*)::int as count FROM credit_notes WHERE entity_id = $1`;
    const params: any[] = [tenant.entityId];

    if (status) {
      params.push(status.toUpperCase());
      const stIdx = params.length;
      sqlQuery += ` AND status = $${stIdx}`;
      countQuery += ` AND status = $${stIdx}`;
    }

    if (search) {
      params.push(`%${search}%`);
      const sIdx = params.length;
      sqlQuery += ` AND (credit_note_number ILIKE $${sIdx} OR reference_number ILIKE $${sIdx})`;
      countQuery += ` AND (credit_note_number ILIKE $${sIdx} OR reference_number ILIKE $${sIdx})`;
    }

    sqlQuery += ` ORDER BY credit_note_date DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    try {
      const [rows, countRes] = await Promise.all([
        client.unsafe(sqlQuery, [...params, limit, offset]),
        client.unsafe(countQuery, params),
      ]);

      const totalCount = countRes[0]?.count ?? 0;

      for (const row of rows ?? []) {
        if (row.customer_id) {
          const cust = await client.unsafe(
            `SELECT id, display_name, customer_number FROM customers WHERE id = $1 LIMIT 1`,
            [row.customer_id],
          );
          row.customer = cust[0] ?? null;
        } else {
          row.customer = null;
        }

        const items = await client.unsafe(
          `SELECT cni.id, cni.quantity, cni.rate, cni.line_total, cni.description, cni.product_id, p.product_name, p.item_code
           FROM credit_note_items cni
           LEFT JOIN products p ON p.id = cni.product_id
           WHERE cni.credit_note_id = $1`,
          [row.id],
        );

        row.items = (items ?? []).map((item: any) => ({
          ...item,
          product: item.product_id
            ? { id: item.product_id, product_name: item.product_name, item_code: item.item_code }
            : null,
        }));
      }

      return { data: rows ?? [], total: totalCount, page, limit };
    } catch (error) {
      throw new InternalServerErrorException((error as Error).message);
    }
  }

  async create(dto: CreateCreditNoteDto, tenant: TenantContext) {
    try {
      const createdRows = await client.unsafe(
        `INSERT INTO credit_notes (
          entity_id, customer_id, credit_note_number, reference_number, credit_note_date,
          status, grand_total, subtotal, tax_total, shipping_charges, adjustment_amount,
          customer_notes, terms_conditions
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        RETURNING id`,
        [
          tenant.entityId,
          dto.customerId,
          dto.creditNoteNumber,
          dto.referenceNumber ?? null,
          dto.creditNoteDate ?? new Date().toISOString().split("T")[0],
          dto.status,
          dto.grandTotal,
          dto.subTotal ?? 0,
          dto.taxTotal ?? 0,
          dto.shippingAmount ?? 0,
          dto.adjustmentAmount ?? 0,
          dto.customerNotes ?? null,
          dto.termsAndConditions ?? null,
        ],
      );

      const cn = createdRows[0];
      if (!cn) {
        throw new Error("Failed to create credit note");
      }

      const validItems = (dto.items ?? []).filter((item) => item.productId);
      if (validItems.length > 0) {
        for (const item of validItems) {
          await client.unsafe(
            `INSERT INTO credit_note_items (
              credit_note_id, product_id, description, quantity, rate, discount_type,
              discount_value, discount_amount, taxable_amount, tax_percentage, tax_amount, line_total
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
            [
              cn.id,
              item.productId,
              item.description ?? null,
              item.quantity,
              item.rate,
              item.discountType ?? "PERCENTAGE",
              item.discountValue ?? 0,
              item.discountAmount ?? 0,
              item.taxableAmount ?? item.lineTotal,
              item.taxPercentage ?? 0,
              item.taxAmount ?? 0,
              item.lineTotal,
            ],
          );
        }
      }

      return { id: cn.id, status: dto.status };
    } catch (err) {
      throw new Error(`Failed to create credit note: ${(err as Error).message}`);
    }
  }

  async findOne(id: string, tenant: TenantContext) {
    try {
      const rows = await client.unsafe(
        `SELECT * FROM credit_notes WHERE id = $1 AND entity_id = $2 LIMIT 1`,
        [id, tenant.entityId],
      );

      const data = rows[0];
      if (!data) throw new Error("Credit note not found");

      if (data.customer_id) {
        const cust = await client.unsafe(
          `SELECT id, display_name, customer_number, email, phone FROM customers WHERE id = $1 LIMIT 1`,
          [data.customer_id],
        );
        data.customer = cust[0] ?? null;
      } else {
        data.customer = null;
      }

      const items = await client.unsafe(
        `SELECT cni.*, p.product_name, p.item_code
         FROM credit_note_items cni
         LEFT JOIN products p ON p.id = cni.product_id
         WHERE cni.credit_note_id = $1`,
        [id],
      );

      data.items = (items ?? []).map((item: any) => ({
        ...item,
        product: item.product_id
          ? { id: item.product_id, product_name: item.product_name, item_code: item.item_code }
          : null,
      }));

      return data;
    } catch (error) {
      throw new InternalServerErrorException((error as Error).message);
    }
  }
}
