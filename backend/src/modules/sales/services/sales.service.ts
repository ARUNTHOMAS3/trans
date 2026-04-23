import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from "@nestjs/common";
import { SupabaseService } from "../../supabase/supabase.service";

@Injectable()
export class SalesService {
  constructor(private readonly supabaseService: SupabaseService) { }

  async getSalesOrderById(id: string) {
    const client = this.supabaseService.getClient();
    const { data: order, error: orderError } = await client
      .from("sales_orders")
      .select("*")
      .eq("id", id)
      .single();

    if (orderError) throw orderError;

    let customer: any = null;
    if (order?.customer_id) {
      const { data: customerData } = await client
        .from("customers")
        .select(
          `
          id,
          display_name,
          first_name,
          last_name,
          company_name,
          billing_address_street_1,
          billing_address_street_2,
          billing_city,
          billing_pincode,
          billing_state,
          shipping_address_street_1,
          shipping_address_street_2,
          shipping_city,
          shipping_pincode,
          shipping_state
        `,
        )
        .eq("id", order.customer_id)
        .maybeSingle();
      customer = customerData ?? null;
    }

    const { data: items, error: itemsError } = await client
      .from("sales_order_items")
      .select(
        `
        *,
        product:products(
          id,
          product_name,
          sku,
          item_code,
          unit_id,
          unit:units(unit_name)
        )
      `,
      )
      .eq("sales_order_id", id)
      .order("line_no", { ascending: true });

    if (itemsError) throw itemsError;

    return {
      ...order,
      customer,
      items: items ?? [],
    };
  }

  async getSalesByType(type: string) {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("sales_orders")
      .select(
        "*, customer:customers(id, display_name, first_name, last_name, company_name)",
      )
      .eq("document_type", type)
      .order("created_at", { ascending: false });

    if (error) throw error;
    return data;
  }

  async getSalesOrdersByCustomer(customerId: string) {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("sales_orders")
      .select(
        "*, customer:customers(id, display_name, first_name, last_name, company_name)",
      )
      .eq("customer_id", customerId)
      .order("created_at", { ascending: false });

    if (error) throw error;
    return data;
  }

  async getPayments() {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("sales_payments")
      .select("*")
      .order("created_at", { ascending: false });
    if (error) throw error;
    return data ?? [];
  }

  async createPayment(body: any, orgId: string) {
    const client = this.supabaseService.getClient();
    const payload = {
      ...body,
      org_id: body?.org_id ?? orgId,
      created_at: body?.created_at ?? new Date().toISOString(),
      updated_at: body?.updated_at ?? new Date().toISOString(),
    };
    const { data, error } = await client
      .from("sales_payments")
      .insert([payload])
      .select("*")
      .single();
    if (error) throw error;
    return data;
  }

  async getPaymentLinks() {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("sales_payment_links")
      .select("*")
      .order("created_at", { ascending: false });
    if (error) throw error;
    return data ?? [];
  }

  async createPaymentLink(body: any, orgId: string) {
    const client = this.supabaseService.getClient();
    const payload = {
      ...body,
      org_id: body?.org_id ?? orgId,
      created_at: body?.created_at ?? new Date().toISOString(),
      updated_at: body?.updated_at ?? new Date().toISOString(),
    };
    const { data, error } = await client
      .from("sales_payment_links")
      .insert([payload])
      .select("*")
      .single();
    if (error) throw error;
    return data;
  }

  async getEWayBills() {
    const client = this.supabaseService.getClient();
    const { data, error } = await client
      .from("sales_eway_bills")
      .select("*")
      .order("created_at", { ascending: false });
    if (error) throw error;
    return data ?? [];
  }

  async createEWayBill(body: any, orgId: string) {
    const client = this.supabaseService.getClient();
    const payload = {
      ...body,
      org_id: body?.org_id ?? orgId,
      created_at: body?.created_at ?? new Date().toISOString(),
      updated_at: body?.updated_at ?? new Date().toISOString(),
    };
    const { data, error } = await client
      .from("sales_eway_bills")
      .insert([payload])
      .select("*")
      .single();
    if (error) throw error;
    return data;
  }

  async createSalesOrder(body: any, orgId: string) {
    const client = this.supabaseService.getClient();

    const {
      customerId,
      saleNumber,
      reference,
      saleDate,
      expectedShipmentDate,
      paymentTerms, // UUID — maps to payment_term_id
      deliveryMethod,
      salesperson, // UUID or name — maps to salesperson_name
      status,
      documentType,
      shippingCharges,
      adjustment,
      customerNotes,
      termsAndConditions,
      subTotal,
      taxTotal,
      total,
      items = [],
    } = body;

    if (!customerId) throw new BadRequestException("customerId is required");
    if (!documentType)
      throw new BadRequestException("documentType is required");

    // Build a map of taxId → { associateTaxId, taxRate } by resolving tax groups
    // sales_order_items.tax_id FK references tax_rates, but the UI sends tax_groups UUIDs.
    const taxIdSet = [
      ...new Set((items as any[]).map((i) => i.taxId).filter(Boolean)),
    ];
    const taxResolutionMap = new Map<
      string,
      { tax_id: string | null; tax_rate: number }
    >();

    if (taxIdSet.length > 0) {
      // Check which IDs exist in tax_rates
      const { data: assocTaxes } = await client
        .from("tax_rates")
        .select("id, tax_rate")
        .in("id", taxIdSet);

      for (const t of assocTaxes ?? []) {
        taxResolutionMap.set(t.id, {
          tax_id: t.id,
          tax_rate: Number(t.tax_rate),
        });
      }

      // For IDs not found in tax_rates, resolve via tax_groups
      const unresolved = taxIdSet.filter((id) => !taxResolutionMap.has(id));
      if (unresolved.length > 0) {
        const { data: groups } = await client
          .from("tax_groups")
          .select("id, tax_rate")
          .in("id", unresolved);
        for (const g of groups ?? []) {
          taxResolutionMap.set(g.id, {
            tax_id: null,
            tax_rate: Number(g.tax_rate),
          });
        }
      }
    }

    // Compute line-item aggregates
    let computedSubTotal = 0;
    let computedDiscountTotal = 0;
    let computedTotalQuantity = 0;
    let computedTaxTotal = 0;

    const processedItems = (items as any[]).map((item, index) => {
      const qty = Number(item.quantity) || 0;
      const rate = Number(item.rate) || 0;
      const discountValue = Number(item.discount) || 0;
      const discountType: string = item.discountType || "%";

      const base = qty * rate;
      const discountAmount =
        discountType === "value" ? discountValue : base * (discountValue / 100);
      const lineAmount = base - discountAmount;

      const taxResolved = item.taxId
        ? (taxResolutionMap.get(item.taxId) ?? { tax_id: null, tax_rate: 0 })
        : { tax_id: null, tax_rate: 0 };
      const lineTaxAmount = lineAmount * (taxResolved.tax_rate / 100);

      computedSubTotal += lineAmount;
      computedDiscountTotal += discountAmount;
      computedTotalQuantity += qty;
      computedTaxTotal += lineTaxAmount;

      return {
        org_id: orgId,
        line_no: index + 1,
        product_id: item.itemId,
        description: item.description ?? null,
        quantity: qty,
        rate: rate,
        discount_type: discountType,
        discount_value: discountValue,
        discount_amount: discountAmount,
        tax_id: taxResolved.tax_id,
        tax_rate: taxResolved.tax_rate,
        tax_amount: lineTaxAmount,
        amount: lineAmount,
      };
    });

    const finalSubTotal = Number(subTotal) || computedSubTotal;
    const finalTaxTotal = Number(taxTotal) || computedTaxTotal;
    const finalShipping = Number(shippingCharges) || 0;
    const finalAdjustment = Number(adjustment) || 0;
    const finalTotal =
      Number(total) ||
      finalSubTotal + finalTaxTotal + finalShipping + finalAdjustment;

    const { data: order, error } = await client
      .from("sales_orders")
      .insert({
        org_id: orgId,
        customer_id: customerId,
        sale_number: saleNumber || null,
        reference: reference || null,
        sale_date: saleDate || new Date().toISOString(),
        expected_shipment_date: expectedShipmentDate || null,
        payment_term_id: paymentTerms || null,
        delivery_method: deliveryMethod || null,
        salesperson_name: salesperson || null,
        status: status || "Draft",
        document_type: documentType,
        sub_total: finalSubTotal,
        tax_total: finalTaxTotal,
        discount_total: computedDiscountTotal,
        shipping_charges: finalShipping,
        adjustment: finalAdjustment,
        total_quantity: computedTotalQuantity,
        total: finalTotal,
        customer_notes: customerNotes || null,
        terms_and_conditions: termsAndConditions || null,
      })
      .select()
      .single();

    if (error) throw error;

    if (processedItems.length > 0) {
      const { error: itemsError } = await client
        .from("sales_order_items")
        .insert(
          processedItems.map((item) => ({
            ...item,
            sales_order_id: order.id,
          })),
        );

      if (itemsError) {
        // Compensating delete — keep the DB clean if items insert fails
        await client.from("sales_orders").delete().eq("id", order.id);
        throw itemsError;
      }
    }

    return order;
  }

  async updateSalesOrder(id: string, body: any, orgId: string) {
    const client = this.supabaseService.getClient();

    // Verify order exists
    const { data: existing, error: fetchError } = await client
      .from("sales_orders")
      .select("id")
      .eq("id", id)
      .single();

    if (fetchError || !existing)
      throw new NotFoundException(`Sales order ${id} not found`);

    const {
      customerId,
      saleNumber,
      reference,
      saleDate,
      expectedShipmentDate,
      paymentTerms,
      deliveryMethod,
      salesperson,
      status,
      shippingCharges,
      adjustment,
      customerNotes,
      termsAndConditions,
      subTotal,
      taxTotal,
      total,
      items = [],
    } = body;

    // Resolve tax IDs (same logic as create)
    const taxIdSet = [
      ...new Set((items as any[]).map((i) => i.taxId).filter(Boolean)),
    ];
    const taxResolutionMap = new Map<
      string,
      { tax_id: string | null; tax_rate: number }
    >();

    if (taxIdSet.length > 0) {
      const { data: assocTaxes } = await client
        .from("tax_rates")
        .select("id, tax_rate")
        .in("id", taxIdSet);

      for (const t of assocTaxes ?? []) {
        taxResolutionMap.set(t.id, {
          tax_id: t.id,
          tax_rate: Number(t.tax_rate),
        });
      }

      const unresolved = taxIdSet.filter((id) => !taxResolutionMap.has(id));
      if (unresolved.length > 0) {
        const { data: groups } = await client
          .from("tax_groups")
          .select("id, tax_rate")
          .in("id", unresolved);
        for (const g of groups ?? []) {
          taxResolutionMap.set(g.id, {
            tax_id: null,
            tax_rate: Number(g.tax_rate),
          });
        }
      }
    }

    let computedSubTotal = 0;
    let computedDiscountTotal = 0;
    let computedTotalQuantity = 0;
    let computedTaxTotal = 0;

    const processedItems = (items as any[]).map((item, index) => {
      const qty = Number(item.quantity) || 0;
      const rate = Number(item.rate) || 0;
      const discountValue = Number(item.discount) || 0;
      const discountType: string = item.discountType || "%";

      const base = qty * rate;
      const discountAmount =
        discountType === "value" ? discountValue : base * (discountValue / 100);
      const lineAmount = base - discountAmount;

      const taxResolved = item.taxId
        ? (taxResolutionMap.get(item.taxId) ?? { tax_id: null, tax_rate: 0 })
        : { tax_id: null, tax_rate: 0 };
      const lineTaxAmount = lineAmount * (taxResolved.tax_rate / 100);

      computedSubTotal += lineAmount;
      computedDiscountTotal += discountAmount;
      computedTotalQuantity += qty;
      computedTaxTotal += lineTaxAmount;

      return {
        org_id: orgId,
        sales_order_id: id,
        line_no: index + 1,
        product_id: item.itemId,
        description: item.description ?? null,
        quantity: qty,
        rate,
        discount_type: discountType,
        discount_value: discountValue,
        discount_amount: discountAmount,
        tax_id: taxResolved.tax_id,
        tax_rate: taxResolved.tax_rate,
        tax_amount: lineTaxAmount,
        amount: lineAmount,
      };
    });

    const finalSubTotal = Number(subTotal) || computedSubTotal;
    const finalTaxTotal = Number(taxTotal) || computedTaxTotal;
    const finalShipping = Number(shippingCharges) || 0;
    const finalAdjustment = Number(adjustment) || 0;
    const finalTotal =
      Number(total) ||
      finalSubTotal + finalTaxTotal + finalShipping + finalAdjustment;

    // Update the order header
    const { data: order, error: updateError } = await client
      .from("sales_orders")
      .update({
        customer_id: customerId,
        sale_number: saleNumber || null,
        reference: reference || null,
        sale_date: saleDate || null,
        expected_shipment_date: expectedShipmentDate || null,
        payment_term_id: paymentTerms || null,
        delivery_method: deliveryMethod || null,
        salesperson_name: salesperson || null,
        status: status || "Draft",
        sub_total: finalSubTotal,
        tax_total: finalTaxTotal,
        discount_total: computedDiscountTotal,
        shipping_charges: finalShipping,
        adjustment: finalAdjustment,
        total_quantity: computedTotalQuantity,
        total: finalTotal,
        customer_notes: customerNotes || null,
        terms_and_conditions: termsAndConditions || null,
      })
      .eq("id", id)
      .select()
      .single();

    if (updateError) throw updateError;

    // Replace all line items: delete existing, insert new
    const { error: deleteError } = await client
      .from("sales_order_items")
      .delete()
      .eq("sales_order_id", id);

    if (deleteError) throw deleteError;

    if (processedItems.length > 0) {
      const { error: itemsError } = await client
        .from("sales_order_items")
        .insert(processedItems);

      if (itemsError) throw itemsError;
    }

    return order;
  }
}
