import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from "@nestjs/common";
import { SupabaseService } from "../../supabase/supabase.service";

@Injectable()
export class SalesService {
  constructor(private readonly supabaseService: SupabaseService) {}

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
    const productIds = items.map(item => item.itemId || item.productId).filter(Boolean);
    const productMap = new Map<string, { hsn_code: string | null; sales_account_id: string | null }>();
    if (productIds.length > 0) {
      const { data: productsData } = await client
        .from("products")
        .select("id, hsn_code, sales_account_id")
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

    // 2. Fetch default sales account fallback
    let defaultSalesAccountId: string | null = null;
    const { data: salesAcc } = await client
      .from("accounts")
      .select("id")
      .eq("entity_id", orgId)
      .or("user_account_name.ilike.%Sales%,system_account_name.ilike.%Sales%,user_account_name.ilike.%Revenue%,system_account_name.ilike.%Revenue%")
      .limit(1)
      .maybeSingle();
    
    if (salesAcc) {
      defaultSalesAccountId = salesAcc.id;
    } else {
      const { data: anyAcc } = await client
        .from("accounts")
        .select("id")
        .eq("entity_id", orgId)
        .limit(1)
        .maybeSingle();
      if (anyAcc) {
        defaultSalesAccountId = anyAcc.id;
      }
    }

    // 3. Map items with fallback logic
    return items.map(item => {
      const prodId = item.itemId || item.productId;
      const prodInfo = productMap.get(prodId) || { hsn_code: null, sales_account_id: null };
      
      // hsn fallback
      let resolvedHsn = item.hsnCode || item.hsn_code || prodInfo.hsn_code;
      if (!resolvedHsn || resolvedHsn.toString().trim() === "" || resolvedHsn.toString().trim() === "null") {
        resolvedHsn = "0";
      }

      // accounts fallback
      let resolvedAccount = item.accounts || prodInfo.sales_account_id || defaultSalesAccountId;
      
      return {
        ...item,
        hsnCode: resolvedHsn,
        accounts: resolvedAccount,
      };
    });
  }


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
          hsn_code,
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
            hsn_code,
            unit:units(unit_name)
          )
        )
        `,
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
    } = body;

    if (!customerId) throw new BadRequestException("customerId is required");
    if (!documentType)
      throw new BadRequestException("documentType is required");

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
    } = body;

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
      })
      .eq("id", id)
      .select()
      .single();

    if (updateError) throw updateError;

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

  async getInvoices(orgId: string) {
    const client = this.supabaseService.getClient();
    const { data: invoices, error } = await client
      .from("invoice_master")
      .select("*")
      .eq("entity_id", orgId)
      .order("created_at", { ascending: false });

    if (error) throw error;
    if (!invoices || invoices.length === 0) return [];

    const customerIds = Array.from(
      new Set(invoices.map((inv) => inv.customer_id).filter(Boolean))
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

    return invoices.map((inv) => ({
      ...inv,
      customer: inv.customer_id ? customersMap.get(inv.customer_id) || null : null,
    }));
  }

  async getInvoiceById(id: string) {
    const client = this.supabaseService.getClient();
    const { data: invoice, error: invoiceError } = await client
      .from("invoice_master")
      .select("*")
      .eq("id", id)
      .single();

    if (invoiceError) throw invoiceError;

    let customer: any = null;
    if (invoice?.customer_id) {
      const { data: customerData } = await client
        .from("customers")
        .select(`
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
        `)
        .eq("id", invoice.customer_id)
        .maybeSingle();
      customer = customerData ?? null;
    }

    const { data: items, error: itemsError } = await client
      .from("invoice_items")
      .select("*")
      .eq("invoice_id", id);

    if (itemsError) throw itemsError;

    const productIds = (items || []).map((item) => item.product_id).filter(Boolean);
    const productMap = new Map<string, any>();
    if (productIds.length > 0) {
      const { data: productsData } = await client
        .from("products")
        .select(`
          id,
          product_name,
          sku,
          item_code,
          unit_id,
          hsn_code,
          unit:units(unit_name)
        `)
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
      };

      const { data: batches, error: batchesError } = await client
        .from("invoice_item_batches")
        .select(`
          *,
          batch:batch_master(
            id,
            batch_no,
            expiry_date
          )
        `)
        .eq("invoice_item_id", item.id);
      
      if (!batchesError) {
        enrichedItems.push({
          ...enrichedItem,
          batches: batches ?? [],
        });
      } else {
        enrichedItems.push(enrichedItem);
      }
    }

    return {
      ...invoice,
      customer,
      items: enrichedItems,
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
    if (!invoiceNumber) throw new BadRequestException("invoiceNumber is required");
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
        is_batch_allocated: resolvedItems.some((i: any) => i.batches && i.batches.length > 0),
        is_delete: false,
      })
      .select()
      .single();

    if (invoiceError) throw invoiceError;

    try {
      if (salesOrderId) {
        const { error: soErr } = await client
          .from("invoice_sales_orders")
          .insert({
            invoice_id: invoice.id,
            sales_order_id: salesOrderId,
          });
        if (soErr) throw soErr;
      }

      if (packageId) {
        const { error: pkgErr } = await client
          .from("invoice_packages")
          .insert({
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
          })
          .select()
          .single();

        if (itemError) throw itemError;

        if (item.batches && item.batches.length > 0) {
          for (const batch of item.batches) {
            const qty = Number(batch.quantity) || 0;
            const focQty = Number(batch.focQuantity) || 0;
            const totalOutQty = qty + focQty;

            const { data: insertedItemBatch, error: itemBatchError } = await client
              .from("invoice_item_batches")
              .insert({
                invoice_item_id: insertedItem.id,
                batch_id: batch.batchId,
                layer_id: batch.layerId || null,
                warehouse_id: batch.warehouseId || warehouseId,
                bin_id: batch.binId || null,
                quantity: qty,
                foc_quantity: focQty,
                purchase_rate: batch.purchaseRate ? Number(batch.purchaseRate) : null,
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
            }
          }
        }
      }

      return invoice;
    } catch (error) {
      await client.from("invoice_master").delete().eq("id", invoice.id);
      throw error;
    }
  }
}

