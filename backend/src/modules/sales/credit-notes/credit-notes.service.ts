import { Injectable, InternalServerErrorException } from "@nestjs/common";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../supabase/supabase.service";
import { CreateCreditNoteDto } from "./dto/create-credit-note.dto";

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
    let query = this.supabaseService
      .getClient()
      .from("credit_notes")
      .select(
        `
        id,
        credit_note_number,
        reference_number,
        credit_note_date,
        status,
        grand_total,
        subtotal,
        tax_total,
        source_type,
        source_id,
        created_at,
        customer:customers(id, display_name, customer_number),
        items:credit_note_items(
          id,
          quantity,
          rate,
          line_total,
          description,
          product:products(id, product_name, item_code)
        )
      `,
        { count: "exact" },
      )
      .eq("entity_id", tenant.entityId)
      .order("credit_note_date", { ascending: false })
      .range((page - 1) * limit, page * limit - 1);

    if (status) {
      query = query.eq("status", status.toUpperCase());
    }

    if (search) {
      query = query.or(
        `credit_note_number.ilike.%${search}%,reference_number.ilike.%${search}%`,
      );
    }

    const { data, error, count } = await query;
    if (error) throw new InternalServerErrorException(error.message);

    return { data: data ?? [], total: count ?? 0, page, limit };
  }

  async create(dto: CreateCreditNoteDto, tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();

    const { data: cn, error: cnError } = await supabase
      .from("credit_notes")
      .insert({
        entity_id: tenant.entityId,
        customer_id: dto.customerId,
        credit_note_number: dto.creditNoteNumber,
        reference_number: dto.referenceNumber ?? null,
        credit_note_date:
          dto.creditNoteDate ?? new Date().toISOString().split("T")[0],
        status: dto.status,
        grand_total: dto.grandTotal,
        subtotal: dto.subTotal ?? 0,
        tax_total: dto.taxTotal ?? 0,
        shipping_charges: dto.shippingAmount ?? 0,
        adjustment_amount: dto.adjustmentAmount ?? 0,
        customer_notes: dto.customerNotes ?? null,
        terms_conditions: dto.termsAndConditions ?? null,
      })
      .select("id")
      .single();

    if (cnError) {
      throw new Error(`Failed to create credit note: ${cnError.message}`);
    }

    const validItems = (dto.items ?? []).filter((item) => item.productId);
    if (validItems.length > 0) {
      const itemRows = validItems.map((item) => ({
        credit_note_id: cn.id,
        product_id: item.productId,
        description: item.description ?? null,
        quantity: item.quantity,
        rate: item.rate,
        discount_type: item.discountType ?? "PERCENTAGE",
        discount_value: item.discountValue ?? 0,
        discount_amount: item.discountAmount ?? 0,
        taxable_amount: item.taxableAmount ?? item.lineTotal,
        tax_percentage: item.taxPercentage ?? 0,
        tax_amount: item.taxAmount ?? 0,
        line_total: item.lineTotal,
      }));

      const { error: itemsError } = await supabase
        .from("credit_note_items")
        .insert(itemRows);

      if (itemsError) {
        throw new Error(
          `Failed to create credit note items: ${itemsError.message}`,
        );
      }
    }

    return { id: cn.id, status: dto.status };
  }

  async findOne(id: string, tenant: TenantContext) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("credit_notes")
      .select(
        `
        *,
        customer:customers(id, display_name, customer_number, email, phone),
        items:credit_note_items(
          id,
          quantity,
          rate,
          discount_type,
          discount_value,
          discount_amount,
          tax_percentage,
          tax_amount,
          line_total,
          description,
          product:products(id, product_name, item_code)
        )
      `,
      )
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .single();

    if (error) throw new InternalServerErrorException(error.message);
    return data;
  }
}
