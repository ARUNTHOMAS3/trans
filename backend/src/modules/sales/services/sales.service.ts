import { v4 as uuidv4 } from "uuid";
import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from "@nestjs/common";
import { SupabaseService } from "../../supabase/supabase.service";
import { TenantContext } from "../../../common/middleware/tenant.middleware";

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

  private sanitizeSaleNumber(value: unknown): string | null {
    if (typeof value !== "string") return null;
    const trimmed = value.trim();
    if (!trimmed) return null;
    if (/^QT-/i.test(trimmed)) {
      throw new BadRequestException(
        "Sales order number cannot use quote prefix QT-. Use an SO series number instead.",
      );
    }
    return trimmed;
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
        .select("id, display_name, first_name, last_name, company_name")
        .eq("id", order.customer_id)
        .maybeSingle();

      if (customerData) {
        customer = { ...customerData };
        const { data: addresses } = await client
          .from("customer_addresses")
          .select("*")
          .eq("customer_id", order.customer_id)
          .eq("is_active", true);

        if (addresses) {
          const billing = addresses.find((a) => a.is_default_billing) ||
                          addresses.find((a) => a.address_type === "billing");
          if (billing) {
            customer.billing_address_street_1 = billing.address_street;
            customer.billing_address_street_2 = billing.address_place;
            customer.billing_address_city = billing.city;
            customer.billing_address_zip = billing.pincode;
            customer.billing_address_state_id = billing.state;
            customer.billing_address_country_id = billing.country_region;
            customer.billing_address_phone = billing.phone;
          }
          const shipping = addresses.find((a) => a.is_default_shipping) ||
                           addresses.find((a) => a.address_type === "shipping");
          if (shipping) {
            customer.shipping_address_street_1 = shipping.address_street;
            customer.shipping_address_street_2 = shipping.address_place;
            customer.shipping_address_city = shipping.city;
            customer.shipping_address_zip = shipping.pincode;
            customer.shipping_address_state_id = shipping.state;
            customer.shipping_address_country_id = shipping.country_region;
            customer.shipping_address_phone = shipping.phone;
          }
        }
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

    // Fetch picklist items for this Sales Order
    const { data: pickItems } = await client
      .from("picklist_items")
      .select("sales_order_line_id, qty_picked, qty_to_pick")
      .eq("sales_order_id", id);

    // Fetch package items for this Sales Order
    const { data: pkgItems } = await client
      .from("inventory_package_items")
      .select("product_id, quantity, package_id")
      .eq("sales_order_id", id);

    const uniquePkgIds = Array.from(new Set((pkgItems ?? []).map((pi: any) => pi.package_id).filter(Boolean)));

    const { data: pkgs } = uniquePkgIds.length > 0 ? await client
      .from("inventory_packages")
      .select("id, status")
      .in("id", uniquePkgIds) : { data: [] };

    // Fetch invoice items for this Sales Order
    const { data: linkedInvoices } = await client
      .from("invoice_sales_orders")
      .select("invoice_id")
      .eq("sales_order_id", id);

    const invoiceIds = (linkedInvoices ?? []).map((li: any) => li.invoice_id);
    let invItems: any[] = [];
    if (invoiceIds.length > 0) {
      const { data } = await client
        .from("invoice_items")
        .select("product_id, quantity")
        .in("invoice_id", invoiceIds);
      invItems = data ?? [];
    }

    const itemsWithMetrics = (items ?? []).map((item: any) => {
      const picked = (pickItems ?? [])
        .filter((pi: any) => pi.sales_order_line_id === item.id)
        .reduce((sum: number, pi: any) => sum + Math.max(Number(pi.qty_picked ?? 0), Number(pi.qty_to_pick ?? 0)), 0);

      const packed = (pkgItems ?? [])
        .filter((pi: any) => {
          const pkg = (pkgs ?? []).find((p: any) => p.id === pi.package_id);
          return pi.product_id === item.product_id && pkg?.status !== 'Shipped';
        })
        .reduce((sum: number, pi: any) => sum + Number(pi.quantity ?? 0), 0);

      const shipped = (pkgItems ?? [])
        .filter((pi: any) => {
          const pkg = (pkgs ?? []).find((p: any) => p.id === pi.package_id);
          return pi.product_id === item.product_id && pkg?.status === 'Shipped';
        })
        .reduce((sum: number, pi: any) => sum + Number(pi.quantity ?? 0), 0);

      const invoiced = invItems
        ?.filter((ii: any) => ii.product_id === item.product_id)
        .reduce((sum: number, ii: any) => sum + Number(ii.quantity ?? 0), 0) ?? 0;

      return {
        ...item,
        picked_quantity: picked,
        packed_quantity: packed,
        shipped_quantity: shipped,
        invoiced_quantity: invoiced,
      };
    });

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
      items: itemsWithMetrics,
    };
  }

  async getSalesByType(type: string, orgId?: string, page = 1, pageSize = 50) {
    const client = this.supabaseService.getClient();

    // Count query for total
    let countQuery = client
      .from("sales_orders")
      .select("id", { count: "exact", head: true })
      .eq("document_type", type)
      .or("is_delete.is.null,is_delete.eq.false");
    if (orgId) countQuery = countQuery.eq("entity_id", orgId);
    const { count } = await countQuery;

    // Data query with pagination
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;

    let query = client
      .from("sales_orders")
      .select(
        "*, customer:customers(id, display_name, first_name, last_name, company_name)",
      )
      .eq("document_type", type)
      .or("is_delete.is.null,is_delete.eq.false")
      .order("created_at", { ascending: false })
      .range(from, to);
    if (orgId) query = query.eq("entity_id", orgId);
    const { data, error } = await query;

    if (error) throw error;
    return {
      data: data ?? [],
      meta: {
        page,
        pageSize,
        total: count ?? 0,
        totalPages: Math.ceil((count ?? 0) / pageSize),
      },
    };
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
      gstTreatment,
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

    const isUnregistered =
      gstTreatment?.toLowerCase() === "unregistered_business" ||
      gstTreatment?.toLowerCase() === "unregistered business";

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
      const lineTaxAmount = isUnregistered ? 0 : (lineAmount * (taxResolved.tax_rate / 100));

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
        tax_id: isUnregistered ? null : taxResolved.tax_id,
        tax_rate: isUnregistered ? 0 : taxResolved.tax_rate,
        tax_amount: isUnregistered ? 0 : lineTaxAmount,
        amount: lineAmount,
        hsn_code: item.hsnCode ?? "0",
        accounts: item.accounts ?? "",
        pricelist: item.pricelist || null,
        warehouse_id: item.warehouseId || item.warehouse_id || warehouseId || null,
        is_invoiced: false,
      };
    });

    const finalSubTotal = Number(subTotal) || computedSubTotal;
    const finalTaxTotal = isUnregistered ? 0 : (Number(taxTotal) || computedTaxTotal);
    const finalShipping = Number(shippingCharges) || 0;
    const finalAdjustment = Number(adjustment) || 0;
    const finalTotal = isUnregistered
      ? (finalSubTotal + finalShipping + finalAdjustment)
      : (Number(total) || (finalSubTotal + finalTaxTotal + finalShipping + finalAdjustment));

    const sanitizedSaleNumber = documentType === "order"
      ? this.sanitizeSaleNumber(saleNumber)
      : (saleNumber || null);

    const { data: order, error } = await client
      .from("sales_orders")
      .insert({
        entity_id: orgId,
        customer_id: customerId,
        sale_number: sanitizedSaleNumber,
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
        gst_treatment: gstTreatment || null,
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
      .select("id, document_type")
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
      documentType = existing.document_type,
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
      gstTreatment,
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

    const isUnregistered =
      gstTreatment?.toLowerCase() === "unregistered_business" ||
      gstTreatment?.toLowerCase() === "unregistered business";

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
      const lineTaxAmount = isUnregistered ? 0 : (lineAmount * (taxResolved.tax_rate / 100));

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
        tax_id: isUnregistered ? null : taxResolved.tax_id,
        tax_rate: isUnregistered ? 0 : taxResolved.tax_rate,
        tax_amount: isUnregistered ? 0 : lineTaxAmount,
        amount: lineAmount,
        hsn_code: item.hsnCode ?? "0",
        accounts: item.accounts ?? "",
        pricelist: item.pricelist || null,
        warehouse_id: item.warehouseId || item.warehouse_id || warehouseId || null,
        is_invoiced: item.is_invoiced ?? item.isInvoiced ?? false,
      };
    });

    const finalSubTotal = Number(subTotal) || computedSubTotal;
    const finalTaxTotal = isUnregistered ? 0 : (Number(taxTotal) || computedTaxTotal);
    const finalShipping = Number(shippingCharges) || 0;
    const finalAdjustment = Number(adjustment) || 0;
    const finalTotal = isUnregistered
      ? (finalSubTotal + finalShipping + finalAdjustment)
      : (Number(total) || (finalSubTotal + finalTaxTotal + finalShipping + finalAdjustment));

    const sanitizedSaleNumber = documentType === "order"
      ? this.sanitizeSaleNumber(saleNumber)
      : (saleNumber || null);

    const { data: order, error: updateError } = await client
      .from("sales_orders")
      .update({
        customer_id: customerId,
        sale_number: sanitizedSaleNumber,
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
        gst_treatment: gstTreatment || null,
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
        .select("id, display_name, first_name, last_name, company_name")
        .eq("id", invoice.customer_id)
        .maybeSingle();

      if (customerData) {
        customer = { ...customerData };
        const { data: addresses } = await client
          .from("customer_addresses")
          .select("*")
          .eq("customer_id", invoice.customer_id)
          .eq("is_active", true);

        if (addresses) {
          const billing = addresses.find((a) => a.is_default_billing) ||
                          addresses.find((a) => a.address_type === "billing");
          if (billing) {
            customer.billing_address_street_1 = billing.address_street;
            customer.billing_address_street_2 = billing.address_place;
            customer.billing_address_city = billing.city;
            customer.billing_address_zip = billing.pincode;
            customer.billing_address_state_id = billing.state;
            customer.billing_address_country_id = billing.country_region;
            customer.billing_address_phone = billing.phone;
          }
          const shipping = addresses.find((a) => a.is_default_shipping) ||
                           addresses.find((a) => a.address_type === "shipping");
          if (shipping) {
            customer.shipping_address_street_1 = shipping.address_street;
            customer.shipping_address_street_2 = shipping.address_place;
            customer.shipping_address_city = shipping.city;
            customer.shipping_address_zip = shipping.pincode;
            customer.shipping_address_state_id = shipping.state;
            customer.shipping_address_country_id = shipping.country_region;
            customer.shipping_address_phone = shipping.phone;
          }
        }
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

  async createInvoice(body: any, orgId: string, tenant?: TenantContext) {
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
      gstTreatment,
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

    const isUnregistered =
      gstTreatment?.toLowerCase() === "unregistered_business" ||
      gstTreatment?.toLowerCase() === "unregistered business";

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
        gst_treatment: gstTreatment || null,
        shipping_charges: Number(shippingCharges) || 0,
        adjustment_amount: Number(adjustmentAmount) || 0,
        round_off: Number(roundOff) || 0,
        subtotal: Number(subtotal) || 0,
        tax_total: isUnregistered ? 0 : (Number(taxTotal) || 0),
        tds_total: Number(tdsTotal) || 0,
        tcs_total: Number(tcsTotal) || 0,
        grand_total: isUnregistered
          ? (Number(subtotal) || 0) + (Number(shippingCharges) || 0) + (Number(adjustmentAmount) || 0) + (Number(roundOff) || 0)
          : (Number(grandTotal) || 0),
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
            tax_id: isUnregistered ? null : (item.taxId || null),
            tax_percentage: isUnregistered ? 0 : (Number(item.taxPercentage) || 0),
            taxable_amount: Number(item.taxableAmount) || 0,
            tax_amount: isUnregistered ? 0 : (Number(item.taxAmount) || 0),
            line_total: isUnregistered ? (Number(item.taxableAmount) || 0) : (Number(item.lineTotal) || 0),
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
                stock_effect_type: "ACCOUNTING",
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

      await this.postInvoiceTransactions(tenant || ({ entityId: orgId, userId: body.user_id || body.userId } as any), invoice, body);

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

  async updateInvoice(id: string, body: any, orgId: string, tenant?: TenantContext) {
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
      gstTreatment,
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

      const isUnregistered =
        gstTreatment?.toLowerCase() === "unregistered_business" ||
        gstTreatment?.toLowerCase() === "unregistered business";

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
          gst_treatment: gstTreatment || null,
          shipping_charges: Number(shippingCharges) || 0,
          adjustment_amount: Number(adjustmentAmount) || 0,
          round_off: Number(roundOff) || 0,
          subtotal: Number(subtotal) || 0,
          tax_total: isUnregistered ? 0 : (Number(taxTotal) || 0),
          tds_total: Number(tdsTotal) || 0,
          tcs_total: Number(tcsTotal) || 0,
          grand_total: isUnregistered
            ? (Number(subtotal) || 0) + (Number(shippingCharges) || 0) + (Number(adjustmentAmount) || 0) + (Number(roundOff) || 0)
            : (Number(grandTotal) || 0),
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
          tax_id: isUnregistered ? null : (item.taxId || null),
          tax_percentage: isUnregistered ? 0 : (Number(item.taxPercentage) || 0),
          taxable_amount: Number(item.taxableAmount) || 0,
          tax_amount: isUnregistered ? 0 : (Number(item.taxAmount) || 0),
          line_total: isUnregistered ? (Number(item.taxableAmount) || 0) : (Number(item.lineTotal) || 0),
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
                stock_effect_type: "ACCOUNTING",
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

      await this.postInvoiceTransactions(tenant || ({ entityId: orgId, userId: body.user_id || body.userId } as any), invoice, body);

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

  async getAwaitingPoApprovals(tenant: TenantContext) {
    const starlexOrgEntityId = "66d79887-be98-40ab-ac40-9e0a008f9d8a";
    const targetOrgId = (tenant.entityId && tenant.entityId !== "00000000-0000-0000-0000-000000000002")
      ? tenant.entityId
      : starlexOrgEntityId;

    const client = this.supabaseService.getClient();

    // 2. Resolve all branches under Starlex
    const { data: branches, error: branchesError } = await client
      .from("organisation_branch_master")
      .select("id, name, ref_id")
      .eq("parent_id", targetOrgId)
      .eq("type", "BRANCH");

    if (branchesError || !branches || branches.length === 0) {
      return [];
    }

    const branchEntityIds = branches.map((b) => b.id);
    const branchNameMap = new Map<string, string>();
    const branchRefMap = new Map<string, string>();
    for (const b of branches) {
      branchNameMap.set(b.id, b.name);
      if (b.ref_id) {
        branchRefMap.set(b.id, b.ref_id);
      }
    }

    // Resolve credit limits from customer records where associated_branch_id = branch.ref_id
    const branchRefIds = branches.map((b) => b.ref_id).filter(Boolean);
    const branchCreditLimitMap = new Map<string, number>();
    if (branchRefIds.length > 0) {
      const { data: custs } = await client
        .from("customers")
        .select("associated_branch_id, credit_limit")
        .in("associated_branch_id", branchRefIds)
        .eq("entity_id", targetOrgId);
      if (custs) {
        for (const c of custs) {
          if (c.associated_branch_id) {
            branchCreditLimitMap.set(
              c.associated_branch_id,
              c.credit_limit ? parseFloat(c.credit_limit.toString()) : 0.0
            );
          }
        }
      }
    }

    // 3. Find POs from these branches that are created against the organization vendor
    // whose status is not 'Draft', and is_delete is false.
    const { data: pos, error: posError } = await client
      .from("purchase_orders")
      .select("id, order_number, order_date, status, warehouse_id, total, entity_id")
      .in("entity_id", branchEntityIds)
      .eq("vendor_id", "db013159-6ac3-49a6-95b1-eaec10f964db")
      .neq("status", "Draft")
      .eq("is_delete", false)
      .order("order_date", { ascending: false });

    if (posError || !pos || pos.length === 0) {
      return [];
    }

    // Resolve warehouse names
    const warehouseIds = pos.map((p) => p.warehouse_id).filter(Boolean);
    const warehouseNameMap = new Map<string, string>();
    if (warehouseIds.length > 0) {
      const { data: whs } = await client
        .from("warehouses")
        .select("id, name")
        .in("id", warehouseIds);
      if (whs) {
        for (const w of whs) {
          warehouseNameMap.set(w.id, w.name);
        }
      }
    }

    // 4. Get all existing references in sales_orders under the parent organization
    // to filter out POs that have already been converted to Sales Orders.
    const poNumbers = pos.map((p) => p.order_number).filter(Boolean);
    let usedPoIds: string[] = [];

    if (poNumbers.length > 0) {
      const { data: sos } = await client
        .from("sales_orders")
        .select("id, reference, sale_date, created_at, status")
        .eq("entity_id", targetOrgId)
        .in("reference", poNumbers)
        .neq("status", "void");

      if (sos && sos.length > 0) {
        for (const po of pos) {
          const poDate = new Date(po.order_date);
          const poDateBuffer = new Date(poDate.getTime() - 24 * 60 * 60 * 1000);

          const isApproved = sos.some((so) => {
            if (so.reference !== po.order_number) return false;
            const soDate = new Date(so.created_at || so.sale_date);
            return soDate >= poDateBuffer;
          });

          if (isApproved) {
            usedPoIds.push(po.id);
          }
        }
      }
    }

    // Filter out used POs
    const filteredPos = pos.filter((po) => !usedPoIds.includes(po.id));

    const result = filteredPos.map((po) => {
      const refId = branchRefMap.get(po.entity_id);
      const creditLimit = refId ? branchCreditLimitMap.get(refId) ?? 0.0 : 0.0;
      
      return {
        id: po.id,
        order_date: po.order_date,
        order_number: po.order_number,
        status: po.status,
        warehouse_name: po.warehouse_id ? warehouseNameMap.get(po.warehouse_id) ?? "Unknown Warehouse" : "Unknown Warehouse",
        branch_name: branchNameMap.get(po.entity_id) ?? "Unknown Branch",
        credit_limit: creditLimit,
        total: po.total ? parseFloat(po.total.toString()) : 0.0,
      };
    });

    return result;
  }

  async approvePurchaseOrders(poIds: string[], tenant: TenantContext) {
    const client = this.supabaseService.getClient();
    const starlexOrgEntityId = "66d79887-be98-40ab-ac40-9e0a008f9d8a";
    const targetOrgId = (tenant.entityId && tenant.entityId !== "00000000-0000-0000-0000-000000000002")
      ? tenant.entityId
      : starlexOrgEntityId;
    
    // Resolve the default sales account for targetOrgId
    const defaultSalesAccountId = await this.resolveDefaultSalesAccountId(targetOrgId);
    
    const results = [];
    for (const poId of poIds) {
      // 1. Fetch PO with items
      const { data: po, error: poError } = await client
        .from("purchase_orders")
        .select("*, items:purchase_order_items(*)")
        .eq("id", poId)
        .single();
      
      if (poError || !po) {
        throw new NotFoundException(`Purchase Order ${poId} not found`);
      }
      
      // 2. Check if Sales Order already exists for this PO (on or after PO order_date)
      const poDate = new Date(po.order_date);
      const poDateBuffer = new Date(poDate.getTime() - 24 * 60 * 60 * 1000).toISOString();
      const { data: existingSo } = await client
        .from("sales_orders")
        .select("id")
        .eq("entity_id", targetOrgId)
        .eq("reference", po.order_number)
        .gte("created_at", poDateBuffer)
        .neq("status", "void")
        .maybeSingle();
      
      if (existingSo) {
        results.push({ poId, status: "already_approved", salesOrderId: existingSo.id });
        continue;
      }
      
      // 3. Find customer record corresponding to the PO's branch
      const { data: branch } = await client
        .from("organisation_branch_master")
        .select("id, name, ref_id")
        .eq("id", po.entity_id)
        .single();
      
      let customerId: string | null = null;
      if (branch && branch.ref_id) {
        const { data: cust } = await client
          .from("customers")
          .select("id")
          .eq("associated_branch_id", branch.ref_id)
          .eq("entity_id", starlexOrgEntityId)
          .maybeSingle();
        if (cust) {
          customerId = cust.id;
        }
      }
      
      // Fallback to customer search by display_name or first customer in list
      if (!customerId) {
        const { data: custs } = await client
          .from("customers")
          .select("id, display_name")
          .eq("entity_id", starlexOrgEntityId);
        
        if (custs && custs.length > 0) {
          const match = branch ? custs.find(c => c.display_name.toLowerCase().includes(branch.name.toLowerCase())) : null;
          customerId = match ? match.id : custs[0].id;
        }
      }
      
      if (!customerId) {
        throw new BadRequestException(`No customer record found for branch ${branch?.name ?? po.entity_id}`);
      }
      
      // Fetch product sales_account_id mapping
      const productIds = (po.items || []).map((item) => item.product_id).filter(Boolean);
      const productMap = new Map<string, string>();
      if (productIds.length > 0) {
        const { data: productsData } = await client
          .from("products")
          .select("id, sales_account_id")
          .in("id", productIds);
        if (productsData) {
          for (const p of productsData) {
            if (p.sales_account_id) {
              productMap.set(p.id, p.sales_account_id);
            }
          }
        }
      }
      
      // Validate tax_ids exist in tax_rates (PO items may reference tax_groups instead)
      const poTaxIds = (po.items || []).map((item) => item.tax_id).filter(Boolean);
      const validTaxIds = new Set<string>();
      if (poTaxIds.length > 0) {
        const { data: taxRatesData } = await client
          .from("tax_rates")
          .select("id")
          .in("id", poTaxIds);
        if (taxRatesData) {
          for (const tr of taxRatesData) {
            validTaxIds.add(tr.id);
          }
        }
      }
      
      // 4. Generate next sales order number
      const { data: maxSo } = await client
        .from("sales_orders")
        .select("sale_number")
        .eq("entity_id", starlexOrgEntityId)
        .like("sale_number", "SO-%");
      
      let maxNum = 0;
      for (const row of maxSo || []) {
        const m = (row.sale_number as string).match(/^SO-(\d+)$/);
        if (m) {
          const num = parseInt(m[1], 10);
          if (num > maxNum) maxNum = num;
        }
      }
      const nextSoNum = `SO-${String(maxNum + 1).padStart(5, "0")}`;
      
      // 4.5 Fetch the default warehouse for the destination organization (Starlex ORG)
      let defaultWarehouseId: string | null = null;
      let defaultWarehouseName: string | null = null;
      const { data: defaultWhData } = await client
        .from("warehouses")
        .select("id, name")
        .eq("entity_id", starlexOrgEntityId)
        .eq("is_default_for_branch", true)
        .maybeSingle();

      if (defaultWhData) {
        defaultWarehouseId = defaultWhData.id;
        defaultWarehouseName = defaultWhData.name;
      } else {
        const { data: fallbackWhData } = await client
          .from("warehouses")
          .select("id, name")
          .eq("entity_id", starlexOrgEntityId)
          .limit(1)
          .maybeSingle();
        if (fallbackWhData) {
          defaultWarehouseId = fallbackWhData.id;
          defaultWarehouseName = fallbackWhData.name;
        }
      }

      // 5. Insert Sales Order header
      const subtotal = po.subtotal ? parseFloat(po.subtotal.toString()) : 0.0;
      const taxAmount = po.tax_amount ? parseFloat(po.tax_amount.toString()) : 0.0;
      const total = po.total ? parseFloat(po.total.toString()) : 0.0;
      const discount = po.discount ? parseFloat(po.discount.toString()) : 0.0;
      const adjustment = po.adjustment ? parseFloat(po.adjustment.toString()) : 0.0;
      
      const { data: so, error: soError } = await client
        .from("sales_orders")
        .insert({
          entity_id: starlexOrgEntityId,
          customer_id: customerId,
          sale_number: nextSoNum,
          reference: po.order_number,
          sale_date: new Date().toISOString(),
          status: "confirmed",
          document_type: "order",
          sub_total: subtotal,
          tax_total: taxAmount,
          discount_total: discount,
          adjustment: adjustment,
          total_quantity: po.items ? po.items.reduce((sum, item) => sum + (parseFloat(item.quantity?.toString() || "0")), 0) : 0,
          total: total,
          warehouse_id: defaultWarehouseId,
          warehouse_name: defaultWarehouseName,
          is_delete: false,
        })
        .select()
        .single();
      
      if (soError || !so) {
        throw soError || new BadRequestException("Failed to insert Sales Order");
      }
      
      // 6. Insert Sales Order items
      const soItems = (po.items || []).map((item, index) => {
        const qty = parseFloat(item.quantity?.toString() || "0");
        const rate = parseFloat(item.rate?.toString() || "0");
        const amt = parseFloat(item.amount?.toString() || "0");
        const taxAmt = parseFloat(item.tax_amount?.toString() || "0");
        const discVal = parseFloat(item.discount?.toString() || "0");
        
        const resolvedAccount = productMap.get(item.product_id) || defaultSalesAccountId;
        if (!resolvedAccount) {
          throw new BadRequestException(
            `Missing valid sales account for item. Configure item sales account or create a Stock/Sales account in Starlex ORG.`,
          );
        }
        
        const rawDiscType = item.discount_type || "percentage";
        const discType = rawDiscType === "percentage" ? "%" : rawDiscType === "value" ? "value" : "%";
        
        return {
          sales_order_id: so.id,
          line_no: index + 1,
          product_id: item.product_id,
          description: item.description || null,
          quantity: qty,
          rate: rate,
          discount_type: discType,
          discount_value: discVal,
          discount_amount: discType === "value" ? discVal : (qty * rate) * (discVal / 100),
          tax_id: (item.tax_id && validTaxIds.has(item.tax_id)) ? item.tax_id : null,
          tax_rate: item.item_tax_rate ? parseFloat(item.item_tax_rate.toString()) : 0.0,
          tax_amount: taxAmt,
          amount: amt,
          hsn_code: item.hsn_code || "0",
          accounts: resolvedAccount,
          entity_id: starlexOrgEntityId,
          is_invoiced: false,
        };
      });
      
      if (soItems.length > 0) {
        const { error: itemsError } = await client
          .from("sales_order_items")
          .insert(soItems);
        
        if (itemsError) {
          await client.from("sales_orders").delete().eq("id", so.id);
          throw itemsError;
        }
      }
      
      // 7. AUTOMATICALLY CREATE PICKLIST for this Sales Order
      const { data: maxPl } = await client
        .from("picklist_master")
        .select("picklist_no")
        .eq("entity_id", starlexOrgEntityId)
        .like("picklist_no", "PL-%");
      
      let maxPlNum = 0;
      for (const row of maxPl || []) {
        const m = (row.picklist_no as string).match(/^PL-(\d+)$/);
        if (m) {
          const num = parseInt(m[1], 10);
          if (num > maxPlNum) maxPlNum = num;
        }
      }
      const nextPlNum = `PL-${String(maxPlNum + 1).padStart(5, "0")}`;
      
      const { data: picklist, error: picklistError } = await client
        .from("picklist_master")
        .insert({
          picklist_no: nextPlNum,
          entity_id: starlexOrgEntityId,
          warehouse_id: defaultWarehouseId,
          picklist_date: new Date().toISOString().split("T")[0],
          status: "DRAFT",
          is_delete: false,
          is_entrypass: false,
        })
        .select()
        .single();
      
      if (picklistError || !picklist) {
        throw picklistError || new BadRequestException("Failed to insert Picklist");
      }
      
      // Fetch the created sales order items to map their line IDs
      const { data: createdSoItems } = await client
        .from("sales_order_items")
        .select("id, product_id, quantity")
        .eq("sales_order_id", so.id);
      
      if (createdSoItems && createdSoItems.length > 0) {
        const plItems = createdSoItems.map((soItem) => {
          const qty = parseFloat(soItem.quantity?.toString() || "0");
          return {
            picklist_id: picklist.id,
            product_id: soItem.product_id,
            sales_order_id: so.id,
            sales_order_line_id: soItem.id,
            qty_ordered: qty,
            qty_to_pick: qty,
            qty_picked: 0.0,
            status: "YET_TO_START",
          };
        });
        
        const { error: plItemsError } = await client
          .from("picklist_items")
          .insert(plItems);
        
        if (plItemsError) {
          throw plItemsError;
        }
      }
      
      results.push({ poId, status: "approved", salesOrderId: so.id, picklistId: picklist.id });
    }
    
    return results;
  }

  async updateSalesOrderStatus(id: string, entityId: string, status: string, reason: string) {
    const client = this.supabaseService.getClient();

    const { data: salesOrder, error: fetchError } = await client
      .from('sales_orders')
      .select('status')
      .eq('id', id)
      .eq('entity_id', entityId)
      .single();

    if (fetchError || !salesOrder) {
      throw new NotFoundException(`Sales order not found`);
    }

    const updatePayload: any = {
      status,
      updated_at: new Date().toISOString(),
    };

    if (status.toLowerCase() === 'void') {
      updatePayload.reason_to_void = reason;
    } else if (status.toLowerCase() === 'confirmed') {
      updatePayload.reason_to_confirmed = reason;
    }

    const { data: updatedOrder, error: updateError } = await client
      .from('sales_orders')
      .update(updatePayload)
      .eq('id', id)
      .eq('entity_id', entityId)
      .select()
      .single();

    if (updateError) {
      throw new BadRequestException(`Failed to update sales order status: ${updateError.message}`);
    }

    return updatedOrder;
  }

  private async postInvoiceTransactions(tenant: TenantContext, invoice: any, dto: any) {
    if (!invoice || !invoice.id) return;
    const client = this.supabaseService.getClient();

    const invoiceId = invoice.id;
    const orgId = invoice.entity_id || tenant?.entityId;
    const status = (invoice.status || dto.status || "draft").toString().toLowerCase();

    // 1. If status is draft, remove any existing journal entries and lines for this invoice
    if (status === "draft") {
      const { data: existingJE } = await client
        .from("journal_entries")
        .select("id")
        .eq("entity_id", orgId)
        .eq("source_document_type", "INVOICE")
        .eq("source_document_id", invoiceId)
        .maybeSingle();

      if (existingJE?.id) {
        await client.from("journal_entry_lines").delete().eq("journal_entry_id", existingJE.id);
        await client.from("journal_entries").delete().eq("id", existingJE.id);
      }
      return;
    }

    // 2. Fetch active accounts from accounts table
    const { data: dbAccounts } = await client
      .from("accounts")
      .select("id, system_account_name, user_account_name, account_type, account_group");

    if (!dbAccounts || dbAccounts.length === 0) {
      console.warn("No active accounts found in database for posting invoice transactions");
      return;
    }

    // Resolver helper
    const findAccount = (names: string[], types?: string[]): string | null => {
      const match = dbAccounts.find((acc: any) => {
        const uName = acc.user_account_name?.toLowerCase() || '';
        const sName = acc.system_account_name?.toLowerCase() || '';
        const aName = acc.account_name?.toLowerCase() || '';
        const aType = acc.account_type?.toLowerCase() || '';

        const nameMatch = names.some(n => {
          const ln = n.toLowerCase();
          return uName.includes(ln) || sName.includes(ln) || aName.includes(ln);
        });

        const typeMatch = types ? types.some(t => aType === t.toLowerCase()) : true;
        return nameMatch && typeMatch;
      });

      if (match) return match.id;

      if (types && types.length > 0) {
        const typeMatch = dbAccounts.find((acc: any) =>
          types.some(t => acc.account_type?.toLowerCase() === t.toLowerCase())
        );
        if (typeMatch) return typeMatch.id;
      }

      return dbAccounts[0]?.id || null;
    };

    // 3. Resolve account IDs according to specs in fix/invoice.txt
    const accountsReceivableId = findAccount(['Accounts Receivable'], ['Accounts Receivable']);
    const accountsReceivableDiscountId = findAccount(['Accounts Receivable (discount)', 'Accounts Receivable discount'], ['Accounts Receivable']) || accountsReceivableId;
    const salesDiscountId = findAccount(['Sales Discounts', 'Sales Discount', 'Discount'], ['Income', 'Other Income', 'Expense', 'Other Expense']);
    const salesAccountId = findAccount(['Sales', 'Sales Account', 'General Income'], ['Income', 'Other Income']);
    const otherExpensesId = findAccount(['Other Expenses', 'Other Expense', 'Adjustment', 'Other Income'], ['Expense', 'Other Expense', 'Income', 'Other Income']);
    const outputSgstId = findAccount(['Output SGST', 'SGST'], ['Other Current Liability', 'Other Liability', 'Other Current Asset', 'Other Asset']);
    const outputCgstId = findAccount(['Output CGST', 'CGST'], ['Other Current Liability', 'Other Liability', 'Other Current Asset', 'Other Asset']);
    const outputIgstId = findAccount(['Output IGST', 'IGST'], ['Other Current Liability', 'Other Liability', 'Other Current Asset', 'Other Asset']);
    const tcsPayableId = findAccount(['TCS Payable', 'TCS'], ['Other Current Liability', 'Other Liability']);
    const tdsReceivableId = findAccount(['TDS Receivable', 'TDS'], ['Other Current Asset', 'Other Asset']);
    const cogsId = findAccount(['Cost of Goods Sold', 'COGS'], ['Cost Of Goods Sold', 'Expense', 'Other Expense']);
    const inventoryAssetId = findAccount(['Inventory Asset', 'Stock', 'Finished Goods'], ['Stock', 'Assets', 'Other Current Asset']);

    // 4. Parse amounts
    const discountAmount = parseFloat(invoice.discount_total?.toString() || dto.discountTotal?.toString() || dto.discountAmount?.toString() || '0');
    const taxAmount = parseFloat(invoice.tax_total?.toString() || dto.taxTotal?.toString() || dto.taxAmount?.toString() || '0');
    const tdsAmount = parseFloat(invoice.tds_total?.toString() || dto.tdsTotal?.toString() || '0');
    const tcsAmount = parseFloat(invoice.tcs_total?.toString() || dto.tcsTotal?.toString() || '0');
    const adjustmentAmount = parseFloat(invoice.adjustment_amount?.toString() || dto.adjustmentAmount?.toString() || dto.adjustment?.toString() || '0');
    const subtotalAmount = parseFloat(invoice.subtotal?.toString() || dto.subtotal?.toString() || '0');
    const grandTotalAmount = parseFloat(invoice.grand_total?.toString() || dto.grandTotal?.toString() || '0');
    const invoiceDate = invoice.invoice_date || dto.invoiceDate || new Date().toISOString().split('T')[0];
    const invoiceNumber = invoice.invoice_number || dto.invoiceNumber || `INV-${Date.now()}`;
    const customerId = invoice.customer_id || dto.customerId || null;

    // 5. Determine if IGST is applied
    const isGstInvoice = taxAmount > 0.0001;
    let isIGST = false;

    if (isGstInvoice && dto.items?.length > 0) {
      const taxIds = dto.items.map((item: any) => item.tax_id || item.taxId).filter(Boolean);
      if (taxIds.length > 0) {
        const { data: rates } = await client
          .from('tax_rates')
          .select('tax_type')
          .in('id', taxIds);
        if (rates && rates.some((r: any) => r.tax_type === 'IGST')) {
          isIGST = true;
        }
      }
    }

    // 6. Calculate Inventory / COGS cost from invoice item batches if tracking inventory
    let totalCostOfGoods = 0;
    if (dto.items && Array.isArray(dto.items)) {
      for (const item of dto.items) {
        if (item.batches && Array.isArray(item.batches)) {
          for (const b of item.batches) {
            const bQty = parseFloat(b.quantity?.toString() || '0');
            const bRate = parseFloat(b.purchaseRate?.toString() || b.purchase_rate?.toString() || b.salesRate?.toString() || '0');
            totalCostOfGoods += (bQty * bRate);
          }
        }
      }
    }

    // 7. Resolve user UUID for audit fields
    let currentUserId: string | null = null;
    const userIdVal = tenant?.userId || dto?.user_id || dto?.userId;
    if (userIdVal && this.isUuid(String(userIdVal))) {
      currentUserId = String(userIdVal);
    } else {
      const { data: firstUser } = await client.from("users").select("id").limit(1).maybeSingle();
      if (firstUser) currentUserId = firstUser.id;
    }

    // 8. Find or create journal_entries header
    const { data: existingJE } = await client
      .from("journal_entries")
      .select("id, created_by")
      .eq("entity_id", orgId)
      .eq("source_document_type", "INVOICE")
      .eq("source_document_id", invoiceId)
      .maybeSingle();

    const journalEntryId = existingJE?.id || uuidv4();

    if (existingJE?.id) {
      await client.from("journal_entry_lines").delete().eq("journal_entry_id", existingJE.id);
    }

    const defaultOrgId = "00000000-0000-0000-0000-000000000000";
    const jeHeader = {
      id: journalEntryId,
      org_id: tenant?.orgId || defaultOrgId,
      entity_id: orgId,
      fiscal_year_id: null,
      journal_number: `JE-${invoiceNumber}`,
      journal_type: "INVOICE",
      journal_date: invoiceDate,
      posting_date: invoiceDate,
      reference_number: invoiceNumber,
      narration: invoice.customer_notes || dto.customerNotes || `Sales Invoice ${invoiceNumber}`,
      source_module: "SALES",
      source_document_type: "INVOICE",
      source_document_id: invoiceId,
      currency_code: "INR",
      exchange_rate: 1.0,
      status: "POSTED",
      created_by: existingJE?.created_by || currentUserId,
      updated_by: currentUserId,
    };

    if (existingJE?.id) {
      const { error: updateJeErr } = await client.from("journal_entries").update(jeHeader).eq("id", journalEntryId);
      if (updateJeErr) console.error("Error updating journal_entries for invoice:", updateJeErr.message);
    } else {
      const { error: insertJeErr } = await client.from("journal_entries").insert(jeHeader);
      if (insertJeErr) console.error("Error inserting journal_entries for invoice:", insertJeErr.message);
    }

    // 9. Build double-entry lines for journal_entry_lines
    const entries: any[] = [];
    const addEntry = (accountId: string | null, description: string, debit: number, credit: number) => {
      if (!accountId) return;
      const dVal = Math.round(debit * 100) / 100;
      const cVal = Math.round(credit * 100) / 100;
      if (dVal > 0.0001 || cVal > 0.0001) {
        entries.push({
          id: uuidv4(),
          journal_entry_id: journalEntryId,
          entity_id: orgId,
          org_id: tenant?.orgId || defaultOrgId,
          account_id: accountId,
          transaction_date: invoiceDate,
          reference_number: invoiceNumber,
          description: description,
          debit: dVal,
          credit: cVal,
          source_id: invoiceId,
          source_type: "INVOICE",
          contact_id: customerId,
          contact_type: "customer",
          line_number: null,
        });
      }
    };

    if (!isGstInvoice) {
      // Non GST Invoice Rules:
      // DEBITS:
      addEntry(accountsReceivableId, "Sales Invoice - Accounts Receivable", grandTotalAmount, 0);

      if (discountAmount > 0.0001) {
        addEntry(salesDiscountId, "Invoice - Sales Discount", discountAmount, 0);
      }

      if (adjustmentAmount > 0.0001) {
        addEntry(otherExpensesId, "Invoice - Adjustment", adjustmentAmount, 0);
      }

      if (tdsAmount > 0.0001) {
        addEntry(tdsReceivableId, "Invoice - TDS Receivable", tdsAmount, 0);
      }

      if (totalCostOfGoods > 0.0001) {
        addEntry(cogsId, "Invoice - Cost of Goods Sold", totalCostOfGoods, 0);
      }

      // CREDITS:
      addEntry(salesAccountId, "Invoice - Sales", 0, subtotalAmount > 0 ? subtotalAmount : grandTotalAmount);

      if (discountAmount > 0.0001) {
        addEntry(accountsReceivableDiscountId, "Invoice - Accounts Receivable (discount)", 0, discountAmount);
      }

      if (adjustmentAmount < -0.0001) {
        addEntry(otherExpensesId, "Invoice - Adjustment", 0, Math.abs(adjustmentAmount));
      }

      if (tcsAmount > 0.0001) {
        addEntry(tcsPayableId, "Invoice - TCS Payable", 0, tcsAmount);
      }

      if (totalCostOfGoods > 0.0001) {
        addEntry(inventoryAssetId, "Invoice - Inventory Asset", 0, totalCostOfGoods);
      }
    } else {
      // GST Invoice Rules:
      // DEBITS:
      addEntry(accountsReceivableId, "Sales Invoice - Accounts Receivable", grandTotalAmount, 0);

      if (discountAmount > 0.0001) {
        addEntry(salesDiscountId, "Invoice - Sales Discount", discountAmount, 0);
      }

      if (adjustmentAmount > 0.0001) {
        addEntry(otherExpensesId, "Invoice - Adjustment", adjustmentAmount, 0);
      }

      if (tdsAmount > 0.0001) {
        addEntry(tdsReceivableId, "Invoice - TDS Receivable", tdsAmount, 0);
      }

      if (totalCostOfGoods > 0.0001) {
        addEntry(cogsId, "Invoice - Cost of Goods Sold", totalCostOfGoods, 0);
      }

      // CREDITS:
      addEntry(salesAccountId, "Invoice - Sales", 0, subtotalAmount);

      if (isIGST) {
        addEntry(outputIgstId, "Invoice - Output IGST", 0, taxAmount);
      } else {
        addEntry(outputCgstId, "Invoice - Output CGST", 0, taxAmount / 2);
        addEntry(outputSgstId, "Invoice - Output SGST", 0, taxAmount / 2);
      }

      if (discountAmount > 0.0001) {
        addEntry(accountsReceivableDiscountId, "Invoice - Accounts Receivable (discount)", 0, discountAmount);
      }

      if (adjustmentAmount < -0.0001) {
        addEntry(otherExpensesId, "Invoice - Adjustment", 0, Math.abs(adjustmentAmount));
      }

      if (tcsAmount > 0.0001) {
        addEntry(tcsPayableId, "Invoice - TCS Payable", 0, tcsAmount);
      }

      if (totalCostOfGoods > 0.0001) {
        addEntry(inventoryAssetId, "Invoice - Inventory Asset", 0, totalCostOfGoods);
      }
    }

    if (entries.length > 0) {
      const { error: linesErr } = await client.from("journal_entry_lines").insert(entries);
      if (linesErr) {
        console.error("Error inserting journal_entry_lines for invoice:", linesErr.message);
      }
    }

    // Save journal_id backlink in invoice_master table
    try {
      await client
        .from("invoice_master")
        .update({ journal_id: journalEntryId })
        .eq("id", invoiceId);
    } catch (jeBacklinkErr) {
      console.error("Error updating invoice_master journal_id:", jeBacklinkErr);
    }
  }

}
