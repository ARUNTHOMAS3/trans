import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from "@nestjs/common";
import { SupabaseService } from "../../supabase/supabase.service";

@Injectable()
export class SalesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private isUuid(value: unknown): value is string {
    if (typeof value !== "string") return false;
    const v = value.trim();
    return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
      v,
    );
  }

  private async resolveDefaultSalesAccountId(
    entityId: string,
  ): Promise<string | null> {
    const client = this.supabaseService.getClient();

    const findPreferred = async (scopeEntityId: string): Promise<string | null> => {
      const { data: salesAcc } = await client
        .from("accounts")
        .select("id")
        .eq("entity_id", scopeEntityId)
        .eq("is_active", true)
        .or(
          "user_account_name.ilike.%Sales%,system_account_name.ilike.%Sales%,user_account_name.ilike.%Revenue%,system_account_name.ilike.%Revenue%",
        )
        .limit(1)
        .maybeSingle();
      if (salesAcc?.id) return salesAcc.id.toString();

      const { data: anyAcc } = await client
        .from("accounts")
        .select("id")
        .eq("entity_id", scopeEntityId)
        .eq("is_active", true)
        .limit(1)
        .maybeSingle();
      return anyAcc?.id?.toString() ?? null;
    };

    const local = await findPreferred(entityId);
    if (local) return local;

    const { data: entityRow } = await client
      .from("organisation_branch_master")
      .select("id, type, parent_id")
      .eq("id", entityId)
      .maybeSingle();

    const parentEntityId = entityRow?.parent_id?.toString().trim();
    if (entityRow?.type === "BRANCH" && this.isUuid(parentEntityId)) {
      return await findPreferred(parentEntityId);
    }

    return null;
  }

  private parseToIsoDate(dateStr: string | null | undefined): string | null {
    if (!dateStr) return null;
    if (typeof dateStr !== "string") return dateStr;
    const trimmed = dateStr.trim();
    if (trimmed === "" || trimmed === "null") return null;
    if (/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) {
      return trimmed;
    }
    if (/^\d{2}-\d{2}-\d{4}$/.test(trimmed)) {
      const parts = trimmed.split("-");
      return `${parts[2]}-${parts[1]}-${parts[0]}`;
    }
    try {
      const parsed = new Date(trimmed);
      if (!isNaN(parsed.getTime())) {
        return parsed.toISOString().split("T")[0];
      }
    } catch (e) {
      // ignore
    }
    return trimmed;
  }

  private async resolveItemFields(items: any[], orgId: string): Promise<any[]> {
    if (!items || items.length === 0) return [];
    const client = this.supabaseService.getClient();

    // 1. Fetch product fallbacks
    const productIds = items
      .map((item) => item.itemId || item.productId)
      .filter(Boolean);
    const productMap = new Map<
      string,
      { hsn_code: string | null; sales_account_id: string | null }
    >();
    if (productIds.length > 0) {
      const { data: productsData } = await client
        .from("products")
        .select("id, hsn_code:hsn_sac_code, sales_account_id")
        .in("id", productIds);

      if (productsData) {
        for (const p of productsData) {
          productMap.set(p.id, {
            hsn_code: p.hsn_code,
            sales_account_id: p.sales_account_id,
          });
        }
      }
    }

    // 2. Fetch default sales account fallback (entity first, then parent org)
    const defaultSalesAccountId = await this.resolveDefaultSalesAccountId(orgId);

    // 3. Map items with fallback logic
    return items.map((item) => {
      const prodId = item.itemId || item.productId;
      const prodInfo = productMap.get(prodId) || {
        hsn_code: null,
        sales_account_id: null,
      };

      // hsn fallback
      let resolvedHsn = item.hsnCode || item.hsn_code || prodInfo.hsn_code;
      if (
        !resolvedHsn ||
        resolvedHsn.toString().trim() === "" ||
        resolvedHsn.toString().trim() === "null"
      ) {
        resolvedHsn = "0";
      }

      // accounts fallback
      const resolvedAccountCandidate =
        item.accounts || prodInfo.sales_account_id || defaultSalesAccountId;
      const resolvedAccount = this.isUuid(resolvedAccountCandidate)
        ? resolvedAccountCandidate
        : null;
      if (!resolvedAccount) {
        throw new BadRequestException(
          `Missing valid sales account for item '${item?.name ?? item?.itemName ?? prodId ?? "unknown"}'. Configure item sales account or create a Stock/Sales account in this entity.`,
        );
      }

      return {
        ...item,
        hsnCode: resolvedHsn,
        accounts: resolvedAccount,
      };
    });
  }

  async getSalesOrderById(id: string, orgId?: string) {
    const client = this.supabaseService.getClient();
    let query = client
      .from("sales_orders")
      .select("*")
      .eq("id", id);
    if (orgId) {
      query = query.eq("entity_id", orgId);
    }
    const { data: order, error: orderError } = await query.maybeSingle();

    if (orderError) throw orderError;
    if (!order) {
      throw new NotFoundException("Sales order not found");
    }

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
          billing_address_street_1:billing_address_street,
          billing_address_street_2:billing_address_place,
          billing_address_city:billing_address_city,
          billing_address_zip:billing_address_zip,
          billing_address_state_id:billing_address_state_id,
          billing_address_country_id:billing_address_country_id,
          billing_address_phone:billing_address_phone,
          shipping_address_street_1:shipping_address_street,
          shipping_address_street_2:shipping_address_place,
          shipping_address_city:shipping_address_city,
          shipping_address_zip:shipping_address_zip,
          shipping_address_state_id:shipping_address_state_id,
          shipping_address_country_id:shipping_address_country_id,
          shipping_address_phone:shipping_address_phone,
          billing_state:states!customers_billing_address_state_id_states_id_fk(name),
          billing_country:countries!customers_billing_address_country_id_fkey(name),
          shipping_state:states!customers_shipping_address_state_id_states_id_fk(name),
          shipping_country:countries!customers_shipping_address_country_id_fkey(name)
        `,
        )
        .eq("id", order.customer_id)
        .maybeSingle();

      if (customerData) {
        customer = {
          ...customerData,
          billing_address_state_id: (customerData as any).billing_state?.name || customerData.billing_address_state_id,
          billing_address_country_id: (customerData as any).billing_country?.name || customerData.billing_address_country_id,
          shipping_address_state_id: (customerData as any).shipping_state?.name || customerData.shipping_address_state_id,
          shipping_address_country_id: (customerData as any).shipping_country?.name || customerData.shipping_address_country_id,
        };
      }
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
          hsn_code:hsn_sac_code,
          unit:units(unit_name)
        )
      `,
      )
      .eq("sales_order_id", id)
      .order("line_no", { ascending: true });

    if (itemsError) throw itemsError;

    const total_items = items ? items.length : 0;
    const invoiced_items = items
      ? items.filter(
          (item: any) =>
            item.is_invoiced === true || item.is_invoiced === "true",
        ).length
      : 0;
    const pending_items = total_items - invoiced_items;
    const completion_percentage =
      total_items > 0 ? Math.round((invoiced_items / total_items) * 100) : 0;

    return {
      ...order,
      customer,
      total_items,
      invoiced_items,
      pending_items,
      completion_percentage,
      items: items ?? [],
    };
  }

  async getSalesByType(type: string, orgId?: string) {
    const client = this.supabaseService.getClient();
    let query = client
      .from("sales_orders")
      .select(
        "*, customer:customers(id, display_name, first_name, last_name, company_name)",
      )
      .eq("document_type", type)
      .order("created_at", { ascending: false });
    if (orgId) query = query.eq("entity_id", orgId);
    const { data, error } = await query;

    if (error) throw error;
    return data;
  }

  async getSalesOrdersByCustomer(customerId: string, orgId?: string) {
    const client = this.supabaseService.getClient();
    let query = client
      .from("sales_orders")
      .select(
        `
        *,
        customer:customers(id, display_name, first_name, last_name, company_name),
        items:sales_order_items(
          *,
          product:products(
            id,
            product_name,
            sku,
            item_code,
            unit_id,
            hsn_code:hsn_sac_code,
            unit:units(unit_name)
          )
        )
        `,
      )
      .eq("customer_id", customerId)
      .neq("status", "closed")
      .order("created_at", { ascending: false });
    if (orgId) query = query.eq("entity_id", orgId);
    const { data, error } = await query;

    if (error) throw error;
    if (!data || data.length === 0) return [];

    const enrichedOrders = [];

    for (const order of data) {
      const items = order.items ?? [];

      // Get all invoice IDs linked to this sales order
      const { data: linkedInvoices } = await client
        .from("invoice_sales_orders")
        .select("invoice_id")
        .eq("sales_order_id", order.id);

      const invoiceIds = (linkedInvoices ?? []).map((li: any) => li.invoice_id);
      const invoicedQuantities = new Map<string, number>();

      if (invoiceIds.length > 0) {
        const { data: invItems } = await client
          .from("invoice_items")
          .select("product_id, quantity")
          .in("invoice_id", invoiceIds);

        for (const item of invItems ?? []) {
          const current = invoicedQuantities.get(item.product_id) || 0;
          invoicedQuantities.set(
            item.product_id,
            current + Number(item.quantity),
          );
        }
      }

      const enrichedItems = [];
      for (const item of items) {
        const invoicedQty = invoicedQuantities.get(item.product_id) || 0;
        const pendingQty = Math.max(0, Number(item.quantity) - invoicedQty);

        // Only return items with pending quantity
        if (pendingQty > 0) {
          enrichedItems.push({
            ...item,
            quantity: pendingQty,
          });
        }
      }

      const total_items = items.length;
      const pending_items = enrichedItems.length;
      const invoiced_items = total_items - pending_items;
      const completion_percentage =
        total_items > 0 ? Math.round((invoiced_items / total_items) * 100) : 0;

      enrichedOrders.push({
        ...order,
        total_items,
        invoiced_items,
        pending_items,
        completion_percentage,
        items: enrichedItems,
      });
    }

    return enrichedOrders;
  }

  async getPayments(orgId?: string) {
    const client = this.supabaseService.getClient();
    let query = client
      .from("sales_payments")
      .select("*")
      .order("created_at", { ascending: false });
    if (orgId) query = query.eq("entity_id", orgId);
    const { data, error } = await query;
    if (error) throw error;
    return data ?? [];
  }

  async createPayment(body: any, orgId: string) {
    const client = this.supabaseService.getClient();
    const payload = {
      ...body,
      entity_id: body?.entity_id ?? orgId,
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

  async getPaymentLinks(orgId?: string) {
    const client = this.supabaseService.getClient();
    let query = client
      .from("sales_payment_links")
      .select("*")
      .order("created_at", { ascending: false });
    if (orgId) query = query.eq("entity_id", orgId);
    const { data, error } = await query;
    if (error) throw error;
    return data ?? [];
  }

  async createPaymentLink(body: any, orgId: string) {
    const client = this.supabaseService.getClient();
    const payload = {
      ...body,
      entity_id: body?.entity_id ?? orgId,
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

  async getEWayBills(orgId?: string) {
    const client = this.supabaseService.getClient();
    let query = client
      .from("sales_eway_bills")
      .select("*")
      .order("created_at", { ascending: false });
    if (orgId) query = query.eq("entity_id", orgId);
    const { data, error } = await query;
    if (error) throw error;
    return data ?? [];
  }

  async createEWayBill(body: any, orgId: string) {
    const client = this.supabaseService.getClient();
    const payload = {
      ...body,
      entity_id: body?.entity_id ?? orgId,
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
      paymentTerms,
      deliveryMethod,
      salesperson,
      status,
      documentType,
      shippingCharges,
      adjustment,
      customerNotes,
      termsAndConditions,
      subTotal,
      taxTotal,
      total,
      items: rawItems = [],
      warehouseId,
      priceListId,
      placeOfSupply,
      tdsTcsType,
      tdsTcsTaxId,
      tdsTcsAmount,
    } = body;

    if (!customerId) throw new BadRequestException("customerId is required");
    if (!documentType)
      throw new BadRequestException("documentType is required");

    const sanitizedTdsTcsType = tdsTcsType
      ? (tdsTcsType.toUpperCase() === "TDS"
        ? "TDS"
        : tdsTcsType.toUpperCase() === "TCS"
        ? "TCS"
        : null)
      : null;

    const items = await this.resolveItemFields(rawItems, orgId);

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
        entity_id: orgId,
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
        hsn_code: item.hsnCode ?? "0",
        accounts: item.accounts ?? "",
        pricelist: item.pricelist || null,
        is_invoiced: false,
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
        entity_id: orgId,
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
        warehouse_id: warehouseId || null,
        price_list_id: priceListId || null,
        place_of_supply: placeOfSupply || null,
        tds_tcs_type: sanitizedTdsTcsType,
        tds_tcs_tax_id: tdsTcsTaxId || null,
        tds_tcs_amount: tdsTcsAmount ? Number(tdsTcsAmount) : 0,
        is_delete: false,
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
        await client.from("sales_orders").delete().eq("id", order.id);
        throw itemsError;
      }
    }

    return order;
  }

  async updateSalesOrder(id: string, body: any, orgId: string) {
    const client = this.supabaseService.getClient();

    const { data: existing, error: fetchError } = await client
      .from("sales_orders")
      .select("id")
      .eq("id", id)
      .eq("entity_id", orgId)
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
      items: rawItems = [],
      warehouseId,
      priceListId,
      placeOfSupply,
      tdsTcsType,
      tdsTcsTaxId,
      tdsTcsAmount,
    } = body;

    const sanitizedTdsTcsType = tdsTcsType
      ? (tdsTcsType.toUpperCase() === "TDS"
        ? "TDS"
        : tdsTcsType.toUpperCase() === "TCS"
        ? "TCS"
        : null)
      : null;

    const items = await this.resolveItemFields(rawItems, orgId);

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
        entity_id: orgId,
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
        hsn_code: item.hsnCode ?? "0",
        accounts: item.accounts ?? "",
        pricelist: item.pricelist || null,
        is_invoiced: item.is_invoiced ?? item.isInvoiced ?? false,
      };
    });

    const finalSubTotal = Number(subTotal) || computedSubTotal;
    const finalTaxTotal = Number(taxTotal) || computedTaxTotal;
    const finalShipping = Number(shippingCharges) || 0;
    const finalAdjustment = Number(adjustment) || 0;
    const finalTotal =
      Number(total) ||
      finalSubTotal + finalTaxTotal + finalShipping + finalAdjustment;

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
        warehouse_id: warehouseId || null,
        price_list_id: priceListId || null,
        place_of_supply: placeOfSupply || null,
        tds_tcs_type: sanitizedTdsTcsType,
        tds_tcs_tax_id: tdsTcsTaxId || null,
        tds_tcs_amount: tdsTcsAmount ? Number(tdsTcsAmount) : 0,
      })
      .eq("id", id)
      .eq("entity_id", orgId)
      .select()
      .single();

    if (updateError) throw updateError;

    const { error: deleteError } = await client
      .from("sales_order_items")
      .delete()
      .eq("sales_order_id", id)
      .eq("entity_id", orgId);

    if (deleteError) throw deleteError;

    if (processedItems.length > 0) {
      const { error: itemsError } = await client
        .from("sales_order_items")
        .insert(processedItems);

      if (itemsError) throw itemsError;
    }

    return order;
  }

  async getInvoices(orgId: string) {
    const client = this.supabaseService.getClient();
    const { data: invoices, error } = await client
      .from("invoice_master")
      .select("*")
      .eq("entity_id", orgId)
      .neq("is_delete", true)
      .order("created_at", { ascending: false });

    if (error) throw error;
    if (!invoices || invoices.length === 0) return [];

    const customerIds = Array.from(
      new Set(invoices.map((inv) => inv.customer_id).filter(Boolean)),
    );

    const customersMap = new Map<string, any>();
    if (customerIds.length > 0) {
      const { data: customersData, error: customersError } = await client
        .from("customers")
        .select("id, display_name, first_name, last_name, company_name")
        .in("id", customerIds);

      if (!customersError && customersData) {
        for (const customer of customersData) {
          customersMap.set(customer.id, customer);
        }
      }
    }

    const invoiceIds = invoices.map((inv) => inv.id);
    const invoiceSoMap = new Map<string, { order_number: string; sales_order_id: string }>();
    try {
      if (invoiceIds.length > 0) {
        const { data: linkedLinks } = await client
          .from("invoice_sales_orders")
          .select("invoice_id, sales_order_id")
          .in("invoice_id", invoiceIds);

        if (linkedLinks && linkedLinks.length > 0) {
          const soIds = Array.from(new Set(linkedLinks.map((l) => l.sales_order_id)));
          const { data: sos } = await client
            .from("sales_orders")
            .select("id, sale_number")
            .in("id", soIds);

          const soMap = new Map<string, string>();
          if (sos) {
            for (const so of sos) {
              soMap.set(so.id, so.sale_number);
            }
          }

          for (const link of linkedLinks) {
            const orderNum = soMap.get(link.sales_order_id);
            if (orderNum) {
              invoiceSoMap.set(link.invoice_id, {
                order_number: orderNum,
                sales_order_id: link.sales_order_id,
              });
            }
          }
        }
      }
    } catch (e) {
      // ignore
    }

    return invoices.map((inv) => ({
      ...inv,
      customer: inv.customer_id
        ? customersMap.get(inv.customer_id) || null
        : null,
      order_number: invoiceSoMap.get(inv.id)?.order_number || null,
      sales_order_id: invoiceSoMap.get(inv.id)?.sales_order_id || null,
    }));
  }

  async getInvoiceById(id: string, orgId: string) {
    const client = this.supabaseService.getClient();
    const { data: invoice, error: invoiceError } = await client
      .from("invoice_master")
      .select("*")
      .eq("entity_id", orgId)
      .eq("id", id)
      .single();

    if (invoiceError) throw invoiceError;

    let customer: any = null;
    if (invoice?.customer_id) {
      const { data: customerData } = await client
        .from("customers")
        .select(
          `
          id,
          display_name,
          first_name,
          last_name,
          company_name,
          billing_address_street_1:billing_address_street,
          billing_address_street_2:billing_address_place,
          billing_address_city:billing_address_city,
          billing_address_zip:billing_address_zip,
          billing_address_state_id:billing_address_state_id,
          billing_address_country_id:billing_address_country_id,
          billing_address_phone:billing_address_phone,
          shipping_address_street_1:shipping_address_street,
          shipping_address_street_2:shipping_address_place,
          shipping_address_city:shipping_address_city,
          shipping_address_zip:shipping_address_zip,
          shipping_address_state_id:shipping_address_state_id,
          shipping_address_country_id:shipping_address_country_id,
          shipping_address_phone:shipping_address_phone,
          billing_state:states!customers_billing_address_state_id_states_id_fk(name),
          billing_country:countries!customers_billing_address_country_id_fkey(name),
          shipping_state:states!customers_shipping_address_state_id_states_id_fk(name),
          shipping_country:countries!customers_shipping_address_country_id_fkey(name)
        `,
        )
        .eq("id", invoice.customer_id)
        .maybeSingle();

      if (customerData) {
        customer = {
          ...customerData,
          billing_address_state_id: (customerData as any).billing_state?.name || customerData.billing_address_state_id,
          billing_address_country_id: (customerData as any).billing_country?.name || customerData.billing_address_country_id,
          shipping_address_state_id: (customerData as any).shipping_state?.name || customerData.shipping_address_state_id,
          shipping_address_country_id: (customerData as any).shipping_country?.name || customerData.shipping_address_country_id,
        };
      }
    }

    const { data: items, error: itemsError } = await client
      .from("invoice_items")
      .select("*")
      .eq("invoice_id", id);

    if (itemsError) throw itemsError;

    const productIds = (items || [])
      .map((item) => item.product_id)
      .filter(Boolean);
    const productMap = new Map<string, any>();
    if (productIds.length > 0) {
      const { data: productsData } = await client
        .from("products")
        .select(
          `
          id,
          product_name,
          sku,
          item_code,
          unit_id,
          hsn_code:hsn_sac_code,
          sales_account_id,
          unit:units(unit_name)
        `,
        )
        .in("id", productIds);

      if (productsData) {
        for (const p of productsData) {
          productMap.set(p.id, p);
        }
      }
    }

    const enrichedItems = [];
    for (const item of items || []) {
      const product = productMap.get(item.product_id) || null;
      const enrichedItem = {
        ...item,
        product,
        accounts: item.accounts || product?.sales_account_id || null,
        account_id: item.accounts || product?.sales_account_id || null,
      };

      const { data: batches, error: batchesError } = await client
        .from("invoice_item_batches")
        .select(
          `
          *,
          batch:batch_master(
            id,
            batch_no,
            expiry_date,
            unit_pack,
            manufacture_batch_number,
            manufacture_exp
          )
        `,
        )
        .eq("invoice_item_id", item.id);

      if (!batchesError) {
        let enrichedBatches = batches || [];
        if (batches && batches.length > 0) {
          const binIds = batches.map((b) => b.bin_id).filter((id) => !!id);
          if (binIds.length > 0) {
            const { data: bins, error: binsError } = await client
              .from("bin_master")
              .select("id, bin_code")
              .in("id", binIds);

            if (!binsError && bins) {
              const binMap = new Map(bins.map((b) => [b.id, b]));
              enrichedBatches = batches.map((b) => ({
                ...b,
                bin: b.bin_id ? binMap.get(b.bin_id) || null : null,
              }));
            } else if (binsError) {
              console.error(`[DEBUG] Bins query error for item ${item.id}:`, binsError.message);
            }
          }
        }

        console.log(`[DEBUG] Item ${item.id} batches count: ${enrichedBatches.length}`);
        if (enrichedBatches.length > 0) {
          console.log(`[DEBUG] First batch data:`, JSON.stringify(enrichedBatches[0], null, 2));
        }

        enrichedItems.push({
          ...enrichedItem,
          batches: enrichedBatches,
        });
      } else {
        console.log(`[DEBUG] Batch error for item ${item.id}:`, batchesError.message);
        enrichedItems.push(enrichedItem);
      }
    }

    // Fetch associated sales order id and number
    let orderNumber: string | null = null;
    let salesOrderId: string | null = null;
    try {
      const { data: linked } = await client
        .from("invoice_sales_orders")
        .select("sales_order_id")
        .eq("invoice_id", id)
        .maybeSingle();

      if (linked?.sales_order_id) {
        salesOrderId = linked.sales_order_id;
        const { data: so } = await client
          .from("sales_orders")
          .select("sale_number")
          .eq("id", linked.sales_order_id)
          .maybeSingle();
        if (so) {
          orderNumber = so.sale_number;
        }
      }
    } catch (e) {
      // ignore
    }

    return {
      ...invoice,
      customer,
      items: enrichedItems,
      order_number: orderNumber,
      sales_order_id: salesOrderId,
    };
  }

  async createInvoice(body: any, orgId: string) {
    const client = this.supabaseService.getClient();

    const {
      customerId,
      invoiceNumber,
      invoiceDate,
      dueDate,
      paymentTerms,
      salespersonId,
      subject,
      customerNotes,
      termsConditions,
      priceListId,
      warehouseId,
      placeOfSupply,
      shippingCharges,
      adjustmentAmount,
      roundOff,
      subtotal,
      taxTotal,
      tdsTotal,
      tcsTotal,
      grandTotal,
      inventoryFlowType,
      status,
      salesOrderId,
      packageId,
      items = [],
    } = body;

    if (!customerId) throw new BadRequestException("customerId is required");
    if (!invoiceNumber)
      throw new BadRequestException("invoiceNumber is required");
    if (!invoiceDate) throw new BadRequestException("invoiceDate is required");

    const resolvedItems = await this.resolveItemFields(items, orgId);

    const { data: invoice, error: invoiceError } = await client
      .from("invoice_master")
      .insert({
        entity_id: orgId,
        customer_id: customerId,
        invoice_number: invoiceNumber,
        invoice_date: invoiceDate,
        due_date: dueDate || null,
        payment_terms: paymentTerms || null,
        salesperson_id: salespersonId || null,
        subject: subject || null,
        customer_notes: customerNotes || null,
        terms_conditions: termsConditions || null,
        price_list_id: priceListId || null,
        warehouse_id: warehouseId || null,
        place_of_supply: placeOfSupply || null,
        shipping_charges: Number(shippingCharges) || 0,
        adjustment_amount: Number(adjustmentAmount) || 0,
        round_off: Number(roundOff) || 0,
        subtotal: Number(subtotal) || 0,
        tax_total: Number(taxTotal) || 0,
        tds_total: Number(tdsTotal) || 0,
        tcs_total: Number(tcsTotal) || 0,
        grand_total: Number(grandTotal) || 0,
        inventory_flow_type: inventoryFlowType || "DIRECT_INVOICE",
        status: status || "draft",
        is_batch_allocated: resolvedItems.some(
          (i: any) => i.batches && i.batches.length > 0,
        ),
        is_delete: false,
      })
      .select()
      .single();

    if (invoiceError) throw invoiceError;

    let originalSalesOrderStatus = "confirmed";
    let originalSalesOrderItemsState: any[] = [];
    const updatedLayers: { layerId: string; quantityAdded: number }[] = [];

    try {
      if (salesOrderId) {
        // Fetch current sales order status to restore on rollback
        const { data: soData } = await client
          .from("sales_orders")
          .select("status")
          .eq("id", salesOrderId)
          .eq("entity_id", orgId)
          .single();
        if (soData) {
          originalSalesOrderStatus = soData.status;
        }

        // 1. Get all sales order items for this sales order
        const { data: soItems, error: getSoItemsErr } = await client
          .from("sales_order_items")
          .select("*")
          .eq("sales_order_id", salesOrderId)
          .eq("entity_id", orgId);

        if (getSoItemsErr) throw getSoItemsErr;

        if (soItems && soItems.length > 0) {
          // Keep a copy of original state for rollback
          originalSalesOrderItemsState = soItems.map((item: any) => ({
            id: item.id,
            is_invoiced: item.is_invoiced,
          }));

          // Calculate previously invoiced quantities (excluding the current invoice)
          const { data: linkedInvoices } = await client
            .from("invoice_sales_orders")
            .select("invoice_id")
            .eq("sales_order_id", salesOrderId);

          const invoiceIds = (linkedInvoices ?? []).map(
            (li: any) => li.invoice_id,
          );
          const invoicedQuantities = new Map<string, number>();

          if (invoiceIds.length > 0) {
            const { data: invItems } = await client
              .from("invoice_items")
              .select("product_id, quantity")
              .in("invoice_id", invoiceIds);

            for (const item of invItems ?? []) {
              const current = invoicedQuantities.get(item.product_id) || 0;
              invoicedQuantities.set(
                item.product_id,
                current + Number(item.quantity),
              );
            }
          }

          // Validate new invoice quantities against pending quantities before modifying any DB rows!
          for (const soItem of soItems) {
            const previouslyInvoiced =
              invoicedQuantities.get(soItem.product_id) || 0;
            const pending = Math.max(
              0,
              Number(soItem.quantity) - previouslyInvoiced,
            );

            const newInvoiceItem = resolvedItems.find(
              (item: any) =>
                (item.productId || item.itemId) === soItem.product_id,
            );
            const newInvoiceQty = newInvoiceItem
              ? Number(newInvoiceItem.quantity) || 0
              : 0;

            if (newInvoiceQty > pending) {
              throw new BadRequestException(
                `Invoice quantity (${newInvoiceQty}) exceeds pending quantity (${pending}) for product ID ${soItem.product_id}`,
              );
            }
          }

          // Now apply updates
          const { error: soErr } = await client
            .from("invoice_sales_orders")
            .insert({
              invoice_id: invoice.id,
              sales_order_id: salesOrderId,
            });
          if (soErr) throw soErr;

          for (const soItem of soItems) {
            const previouslyInvoiced =
              invoicedQuantities.get(soItem.product_id) || 0;

            const newInvoiceItem = resolvedItems.find(
              (item: any) =>
                (item.productId || item.itemId) === soItem.product_id,
            );
            const newInvoiceQty = newInvoiceItem
              ? Number(newInvoiceItem.quantity) || 0
              : 0;

            const totalInvoiced = previouslyInvoiced + newInvoiceQty;
            const isFullyInvoiced = totalInvoiced >= Number(soItem.quantity);

            // Update is_invoiced in DB
            const { error: updateItemErr } = await client
              .from("sales_order_items")
              .update({ is_invoiced: isFullyInvoiced })
              .eq("id", soItem.id)
              .eq("entity_id", orgId);
            if (updateItemErr) throw updateItemErr;

            soItem.is_invoiced = isFullyInvoiced; // Update local state for subsequent closing check
          }

          // Check if ALL items under that sales order are now set to is_invoiced == true
          const allInvoiced = soItems.every(
            (item: any) =>
              item.is_invoiced === true || item.is_invoiced === "true",
          );
          if (allInvoiced) {
            // Update sales order status to 'closed'
            const { error: updateSoErr } = await client
              .from("sales_orders")
              .update({ status: "closed" })
              .eq("id", salesOrderId)
              .eq("entity_id", orgId);
            if (updateSoErr) throw updateSoErr;
          }
        }
      }

      if (packageId) {
        const { error: pkgErr } = await client.from("invoice_packages").insert({
          invoice_id: invoice.id,
          package_id: packageId,
        });
        if (pkgErr) throw pkgErr;
      }

      for (const item of resolvedItems) {
        const { data: insertedItem, error: itemError } = await client
          .from("invoice_items")
          .insert({
            invoice_id: invoice.id,
            product_id: item.productId || item.itemId,
            description: item.description || null,
            quantity: Number(item.quantity) || 0,
            rate: Number(item.rate) || 0,
            discount_type: item.discountType || null,
            discount_value: Number(item.discountValue) || 0,
            tax_id: item.taxId || null,
            tax_percentage: Number(item.taxPercentage) || 0,
            taxable_amount: Number(item.taxableAmount) || 0,
            tax_amount: Number(item.taxAmount) || 0,
            line_total: Number(item.lineTotal) || 0,
            foc_quantity: Number(item.focQuantity) || 0,
            hsn_code: item.hsnCode || "0",
            accounts: item.accounts || null,
          })
          .select()
          .single();

        if (itemError) throw itemError;

        if (item.batches && item.batches.length > 0) {
          for (const batch of item.batches) {
            const qty = Number(batch.quantity) || 0;
            const focQty = Number(batch.focQuantity) || 0;
            const totalOutQty = qty + focQty;

            const { error: itemBatchError } = await client
              .from("invoice_item_batches")
              .insert({
                invoice_item_id: insertedItem.id,
                batch_id: batch.batchId,
                layer_id: batch.layerId || null,
                warehouse_id: batch.warehouseId || warehouseId,
                bin_id: batch.binId || null,
                quantity: qty,
                foc_quantity: focQty,
                purchase_rate: batch.purchaseRate
                  ? Number(batch.purchaseRate)
                  : null,
                sales_rate: batch.salesRate ? Number(batch.salesRate) : null,
                mrp: batch.mrp ? Number(batch.mrp) : null,
                expiry_date: this.parseToIsoDate(batch.expiryDate),
                manufacturer_batch: batch.manufacturerBatch || null,
              })
              .select()
              .single();

            if (itemBatchError) throw itemBatchError;

            const { error: transError } = await client
              .from("batch_transactions")
              .insert({
                batch_id: batch.batchId,
                layer_id: batch.layerId || null,
                product_id: item.productId,
                entity_id: orgId,
                warehouse_id: batch.warehouseId || warehouseId,
                bin_id: batch.binId || null,
                trans_type: "INVOICE",
                ref_id: invoice.id,
                ref_no: invoiceNumber,
                qty_in: 0,
                qty_out: totalOutQty,
                rate: batch.salesRate ? Number(batch.salesRate) : null,
                trans_date: invoiceDate,
              });

            if (transError) throw transError;

            if (!packageId && batch.layerId) {
              const { data: currentLayer, error: fetchLayerErr } = await client
                .from("batch_stock_layers")
                .select("qty")
                .eq("id", batch.layerId)
                .single();

              if (fetchLayerErr) throw fetchLayerErr;

              const currentQty = Number(currentLayer.qty) || 0;
              const newQty = Math.max(0, currentQty - totalOutQty);

              const { error: updateLayerErr } = await client
                .from("batch_stock_layers")
                .update({ qty: newQty })
                .eq("id", batch.layerId);

              if (updateLayerErr) throw updateLayerErr;

              updatedLayers.push({
                layerId: batch.layerId,
                quantityAdded: totalOutQty,
              });
            }
          }
        }
      }

      return invoice;
    } catch (error) {
      try {
        await client
          .from("invoice_master")
          .delete()
          .eq("id", invoice.id)
          .eq("entity_id", orgId);

        if (salesOrderId) {
          await client
            .from("sales_orders")
            .update({ status: originalSalesOrderStatus })
            .eq("id", salesOrderId)
            .eq("entity_id", orgId);

          for (const itemState of originalSalesOrderItemsState) {
            await client
              .from("sales_order_items")
              .update({ is_invoiced: itemState.is_invoiced })
              .eq("id", itemState.id)
              .eq("entity_id", orgId);
          }
        }

        for (const layerUpdate of updatedLayers) {
          const { data: currentLayer } = await client
            .from("batch_stock_layers")
            .select("qty")
            .eq("id", layerUpdate.layerId)
            .single();
          if (currentLayer) {
            const currentQty = Number(currentLayer.qty) || 0;
            await client
              .from("batch_stock_layers")
              .update({ qty: currentQty + layerUpdate.quantityAdded })
              .eq("id", layerUpdate.layerId);
          }
        }
      } catch (rollbackError) {
        console.error("Rollback failed:", rollbackError);
      }
      throw error;
    }
  }

  async updateInvoice(id: string, body: any, orgId: string) {
    const client = this.supabaseService.getClient();

    const {
      customerId,
      invoiceNumber,
      invoiceDate,
      dueDate,
      paymentTerms,
      salespersonId,
      subject,
      customerNotes,
      termsConditions,
      priceListId,
      warehouseId,
      placeOfSupply,
      shippingCharges,
      adjustmentAmount,
      roundOff,
      subtotal,
      taxTotal,
      tdsTotal,
      tcsTotal,
      grandTotal,
      inventoryFlowType,
      status,
      salesOrderId,
      packageId,
      items = [],
    } = body;

    if (!customerId) throw new BadRequestException("customerId is required");
    if (!invoiceNumber)
      throw new BadRequestException("invoiceNumber is required");
    if (!invoiceDate) throw new BadRequestException("invoiceDate is required");

    // 1. Resolve new items
    const resolvedItems = await this.resolveItemFields(items, orgId);

    // 2. Fetch old batch transactions for this invoice to revert stock layer quantities
    const { data: oldTx } = await client
      .from("batch_transactions")
      .select("*")
      .eq("ref_id", id)
      .eq("entity_id", orgId)
      .eq("trans_type", "INVOICE");

    const revertedLayers: { layerId: string; quantitySubtracted: number }[] = [];
    try {
      if (oldTx && oldTx.length > 0) {
        for (const tx of oldTx) {
          if (tx.layer_id && tx.qty_out) {
            const { data: layer } = await client
              .from("batch_stock_layers")
              .select("qty")
              .eq("id", tx.layer_id)
              .maybeSingle();
            if (layer) {
              const currentQty = Number(layer.qty) || 0;
              const txQty = Number(tx.qty_out) || 0;
              await client
                .from("batch_stock_layers")
                .update({ qty: currentQty + txQty })
                .eq("id", tx.layer_id);
              revertedLayers.push({ layerId: tx.layer_id, quantitySubtracted: txQty });
            }
          }
        }
      }

      // 3. Delete old batch transactions and old invoice items (which cascades to invoice_item_batches)
      await client
        .from("batch_transactions")
        .delete()
        .eq("ref_id", id)
        .eq("entity_id", orgId)
        .eq("trans_type", "INVOICE");

      await client
        .from("invoice_items")
        .delete()
        .eq("invoice_id", id);

      // 4. Update invoice_master
      const { data: invoice, error: invoiceError } = await client
        .from("invoice_master")
        .update({
          customer_id: customerId,
          invoice_number: invoiceNumber,
          invoice_date: invoiceDate,
          due_date: dueDate || null,
          payment_terms: paymentTerms || null,
          salesperson_id: salespersonId || null,
          subject: subject || null,
          customer_notes: customerNotes || null,
          terms_conditions: termsConditions || null,
          price_list_id: priceListId || null,
          warehouse_id: warehouseId || null,
          place_of_supply: placeOfSupply || null,
          shipping_charges: Number(shippingCharges) || 0,
          adjustment_amount: Number(adjustmentAmount) || 0,
          round_off: Number(roundOff) || 0,
          subtotal: Number(subtotal) || 0,
          tax_total: Number(taxTotal) || 0,
          tds_total: Number(tdsTotal) || 0,
          tcs_total: Number(tcsTotal) || 0,
          grand_total: Number(grandTotal) || 0,
          inventory_flow_type: inventoryFlowType || "DIRECT_INVOICE",
          status: status || "draft",
          is_batch_allocated: resolvedItems.some(
            (i: any) => i.batches && i.batches.length > 0,
          ),
          updated_at: new Date().toISOString(),
        })
        .eq("id", id)
        .eq("entity_id", orgId)
        .select()
        .single();

      if (invoiceError) throw invoiceError;

    // 5. Insert new items (deducting stock layer quantities and creating batches/transactions)
    for (const item of resolvedItems) {
      const { data: insertedItem, error: itemError } = await client
        .from("invoice_items")
        .insert({
          invoice_id: id,
          product_id: item.productId || item.itemId,
          description: item.description || null,
          quantity: Number(item.quantity) || 0,
          rate: Number(item.rate) || 0,
          discount_type: item.discountType || null,
          discount_value: Number(item.discountValue) || 0,
          tax_id: item.taxId || null,
          tax_percentage: Number(item.taxPercentage) || 0,
          taxable_amount: Number(item.taxableAmount) || 0,
          tax_amount: Number(item.taxAmount) || 0,
          line_total: Number(item.lineTotal) || 0,
          foc_quantity: Number(item.focQuantity) || 0,
          hsn_code: item.hsnCode || "0",
          accounts: item.accounts || null,
        })
        .select()
        .single();

      if (itemError) throw itemError;

        if (item.batches && item.batches.length > 0) {
          for (const batch of item.batches) {
            const qty = Number(batch.quantity) || 0;
            const focQty = Number(batch.focQuantity) || 0;
            const totalOutQty = qty + focQty;

            const { error: itemBatchError } = await client
              .from("invoice_item_batches")
              .insert({
                invoice_item_id: insertedItem.id,
                batch_id: batch.batchId,
                layer_id: batch.layerId || null,
                warehouse_id: batch.warehouseId || warehouseId,
                bin_id: batch.binId || null,
                quantity: qty,
                foc_quantity: focQty,
                purchase_rate: batch.purchaseRate
                  ? Number(batch.purchaseRate)
                  : null,
                sales_rate: batch.salesRate ? Number(batch.salesRate) : null,
                mrp: batch.mrp ? Number(batch.mrp) : null,
                expiry_date: this.parseToIsoDate(batch.expiryDate),
                manufacturer_batch: batch.manufacturerBatch || null,
              })
              .select()
              .single();

            if (itemBatchError) throw itemBatchError;

             const { error: transError } = await client
              .from("batch_transactions")
              .insert({
                batch_id: batch.batchId,
                layer_id: batch.layerId || null,
                product_id: item.productId || item.itemId,
                entity_id: orgId,
                warehouse_id: batch.warehouseId || warehouseId,
                bin_id: batch.binId || null,
                trans_type: "INVOICE",
                ref_id: id,
                ref_no: invoiceNumber,
                qty_in: 0,
                qty_out: totalOutQty,
                rate: batch.salesRate ? Number(batch.salesRate) : null,
                trans_date: invoiceDate,
              });

            if (transError) throw transError;

            // Deduct stock layer quantity
            if (batch.layerId) {
              const { data: layerData } = await client
                .from("batch_stock_layers")
                .select("qty")
                .eq("id", batch.layerId)
                .single();
              if (layerData) {
                const currentQty = Number(layerData.qty) || 0;
                const newQty = currentQty - totalOutQty;

                const { error: updateLayerErr } = await client
                  .from("batch_stock_layers")
                  .update({ qty: newQty })
                  .eq("id", batch.layerId);

                if (updateLayerErr) throw updateLayerErr;
              }
            }
          }
        }
      }

      return invoice;
    } catch (error) {
      // Revert stock layer additions made during start of transaction in case of error
      try {
        for (const layerRevert of revertedLayers) {
          const { data: currentLayer } = await client
            .from("batch_stock_layers")
            .select("qty")
            .eq("id", layerRevert.layerId)
            .single();
          if (currentLayer) {
            const currentQty = Number(currentLayer.qty) || 0;
            await client
              .from("batch_stock_layers")
              .update({ qty: currentQty - layerRevert.quantitySubtracted })
              .eq("id", layerRevert.layerId);
          }
        }
      } catch (rollbackError) {
        console.error("Rollback failed:", rollbackError);
      }
      throw error;
    }
  }
}
