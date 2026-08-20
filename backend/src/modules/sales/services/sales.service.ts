import { v4 as uuidv4 } from "uuid";
import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from "@nestjs/common";
import { SupabaseService } from "../../supabase/supabase.service";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { client } from "../../../db/db";

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
    const findPreferred = async (scopeEntityId: string): Promise<string | null> => {
      const salesAcc = await client.unsafe(
        `SELECT id FROM accounts
         WHERE entity_id = $1 AND is_active = true
         AND (user_account_name ILIKE '%Sales%' OR system_account_name ILIKE '%Sales%' OR user_account_name ILIKE '%Revenue%' OR system_account_name ILIKE '%Revenue%')
         LIMIT 1`,
        [scopeEntityId],
      );
      if (salesAcc[0]?.id) return salesAcc[0].id.toString();

      const anyAcc = await client.unsafe(
        `SELECT id FROM accounts WHERE entity_id = $1 AND is_active = true LIMIT 1`,
        [scopeEntityId],
      );
      return anyAcc[0]?.id?.toString() ?? null;
    };

    const local = await findPreferred(entityId);
    if (local) return local;

    const entityRows = await client.unsafe(
      `SELECT id, type, parent_id FROM organisation_branch_master WHERE id = $1 LIMIT 1`,
      [entityId],
    );

    const entityRow = entityRows[0];
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

    const productIds = items
      .map((item) => item.itemId || item.productId)
      .filter(Boolean);
    const productMap = new Map<
      string,
      { hsn_code: string | null; sales_account_id: string | null }
    >();
    if (productIds.length > 0) {
      const productsData = await client.unsafe(
        `SELECT id, hsn_sac_code as hsn_code, sales_account_id FROM products WHERE id = ANY($1)`,
        [productIds],
      );

      if (productsData) {
        for (const p of productsData) {
          productMap.set(p.id, {
            hsn_code: p.hsn_code,
            sales_account_id: p.sales_account_id,
          });
        }
      }
    }

    const defaultSalesAccountId = await this.resolveDefaultSalesAccountId(orgId);

    return items.map((item) => {
      const prodId = item.itemId || item.productId;
      const prodInfo = productMap.get(prodId) || {
        hsn_code: null,
        sales_account_id: null,
      };

      let resolvedHsn = item.hsnCode || item.hsn_code || prodInfo.hsn_code;
      if (
        !resolvedHsn ||
        resolvedHsn.toString().trim() === "" ||
        resolvedHsn.toString().trim() === "null"
      ) {
        resolvedHsn = "0";
      }

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
    let sqlQuery = `SELECT * FROM sales_orders WHERE id = $1`;
    const params: any[] = [id];
    if (orgId) {
      params.push(orgId);
      sqlQuery += ` AND entity_id = $2`;
    }
    sqlQuery += ` LIMIT 1`;

    const orders = await client.unsafe(sqlQuery, params);
    const order = orders[0];
    if (!order) {
      throw new NotFoundException("Sales order not found");
    }

    let customer: any = null;
    if (order?.customer_id) {
      const customers = await client.unsafe(
        `SELECT id, display_name, first_name, last_name, company_name FROM customers WHERE id = $1 LIMIT 1`,
        [order.customer_id],
      );

      if (customers[0]) {
        customer = { ...customers[0] };
        const addresses = await client.unsafe(
          `SELECT * FROM customer_addresses WHERE customer_id = $1 AND is_active = true`,
          [order.customer_id],
        );

        if (addresses) {
          const billing = addresses.find((a: any) => a.is_default_billing) ||
                          addresses.find((a: any) => a.address_type === "billing");
          if (billing) {
            customer.billing_address_street_1 = billing.address_street;
            customer.billing_address_street_2 = billing.address_place;
            customer.billing_address_city = billing.city;
            customer.billing_address_zip = billing.pincode;
            customer.billing_address_state_id = billing.state;
            customer.billing_address_country_id = billing.country_region;
            customer.billing_address_phone = billing.phone;
          }
          const shipping = addresses.find((a: any) => a.is_default_shipping) ||
                           addresses.find((a: any) => a.address_type === "shipping");
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

    const items = await client.unsafe(
      `SELECT soi.*, p.id as p_id, p.product_name, p.sku, p.item_code, p.unit_id, p.hsn_sac_code as hsn_code, u.unit_name
       FROM sales_order_items soi
       LEFT JOIN products p ON p.id = soi.product_id
       LEFT JOIN units u ON u.id = p.unit_id
       WHERE soi.sales_order_id = $1
       ORDER BY soi.line_no ASC`,
      [id],
    );

    const itemsFormatted = (items ?? []).map((item: any) => ({
      ...item,
      product: item.product_id
        ? {
            id: item.product_id,
            product_name: item.product_name,
            sku: item.sku,
            item_code: item.item_code,
            unit_id: item.unit_id,
            hsn_code: item.hsn_code,
            unit: item.unit_name ? { unit_name: item.unit_name } : null,
          }
        : null,
    }));

    const pickItems = await client.unsafe(
      `SELECT sales_order_line_id, qty_picked, qty_to_pick FROM picklist_items WHERE sales_order_id = $1`,
      [id],
    );

    const pkgItems = await client.unsafe(
      `SELECT product_id, quantity, package_id FROM inventory_package_items WHERE sales_order_id = $1`,
      [id],
    );

    const uniquePkgIds = Array.from(new Set((pkgItems ?? []).map((pi: any) => pi.package_id).filter(Boolean)));

    const pkgs = uniquePkgIds.length > 0 ? await client.unsafe(
      `SELECT id, status FROM inventory_packages WHERE id = ANY($1)`,
      [uniquePkgIds],
    ) : [];

    const linkedInvoices = await client.unsafe(
      `SELECT invoice_id FROM invoice_sales_orders WHERE sales_order_id = $1`,
      [id],
    );

    const invoiceIds = (linkedInvoices ?? []).map((li: any) => li.invoice_id);
    let invItems: any[] = [];
    if (invoiceIds.length > 0) {
      invItems = await client.unsafe(
        `SELECT product_id, quantity FROM invoice_items WHERE invoice_id = ANY($1)`,
        [invoiceIds],
      );
    }

    const itemsWithMetrics = (itemsFormatted ?? []).map((item: any) => {
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

    const total_items = itemsFormatted ? itemsFormatted.length : 0;
    const invoiced_items = itemsFormatted
      ? itemsFormatted.filter(
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
    const offset = (page - 1) * pageSize;

    let sqlQuery = `SELECT so.*, c.id as c_id, c.display_name, c.first_name, c.last_name, c.company_name
                    FROM sales_orders so
                    LEFT JOIN customers c ON c.id = so.customer_id
                    WHERE so.document_type = $1 AND (so.is_delete IS NULL OR so.is_delete = false)`;
    let countQuery = `SELECT COUNT(*)::int as count FROM sales_orders WHERE document_type = $1 AND (is_delete IS NULL OR is_delete = false)`;
    const params: any[] = [type];

    if (orgId) {
      params.push(orgId);
      sqlQuery += ` AND so.entity_id = $2`;
      countQuery += ` AND entity_id = $2`;
    }

    sqlQuery += ` ORDER BY so.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    const [data, countRes] = await Promise.all([
      client.unsafe(sqlQuery, [...params, pageSize, offset]),
      client.unsafe(countQuery, params),
    ]);

    const totalCount = countRes[0]?.count ?? 0;

    const formattedData = (data ?? []).map((row: any) => ({
      ...row,
      customer: row.customer_id
        ? {
            id: row.c_id,
            display_name: row.display_name,
            first_name: row.first_name,
            last_name: row.last_name,
            company_name: row.company_name,
          }
        : null,
    }));

    return {
      data: formattedData,
      meta: {
        page,
        pageSize,
        total: totalCount,
        totalPages: Math.ceil(totalCount / pageSize),
      },
    };
  }

  async getSalesOrdersByCustomer(customerId: string, orgId?: string) {
    let sqlQuery = `SELECT * FROM sales_orders WHERE customer_id = $1 AND status != 'closed'`;
    const params: any[] = [customerId];
    if (orgId) {
      params.push(orgId);
      sqlQuery += ` AND entity_id = $2`;
    }
    sqlQuery += ` ORDER BY created_at DESC`;

    const data = await client.unsafe(sqlQuery, params);
    if (!data || data.length === 0) return [];

    const enrichedOrders = [];

    for (const order of data) {
      const items = await client.unsafe(
        `SELECT soi.*, p.product_name, p.sku, p.item_code, p.unit_id, p.hsn_sac_code as hsn_code, u.unit_name
         FROM sales_order_items soi
         LEFT JOIN products p ON p.id = soi.product_id
         LEFT JOIN units u ON u.id = p.unit_id
         WHERE soi.sales_order_id = $1`,
        [order.id],
      );

      const formattedItems = (items ?? []).map((item: any) => ({
        ...item,
        product: item.product_id
          ? {
              id: item.product_id,
              product_name: item.product_name,
              sku: item.sku,
              item_code: item.item_code,
              unit_id: item.unit_id,
              hsn_code: item.hsn_code,
              unit: item.unit_name ? { unit_name: item.unit_name } : null,
            }
          : null,
      }));

      const linkedInvoices = await client.unsafe(
        `SELECT invoice_id FROM invoice_sales_orders WHERE sales_order_id = $1`,
        [order.id],
      );

      const invoiceIds = (linkedInvoices ?? []).map((li: any) => li.invoice_id);
      const invoicedQuantities = new Map<string, number>();

      if (invoiceIds.length > 0) {
        const invItems = await client.unsafe(
          `SELECT product_id, quantity FROM invoice_items WHERE invoice_id = ANY($1)`,
          [invoiceIds],
        );

        for (const item of invItems ?? []) {
          const current = invoicedQuantities.get(item.product_id) || 0;
          invoicedQuantities.set(
            item.product_id,
            current + Number(item.quantity),
          );
        }
      }

      const enrichedItems = [];
      for (const item of formattedItems) {
        const invoicedQty = invoicedQuantities.get(item.product_id) || 0;
        const pendingQty = Math.max(0, Number(item.quantity) - invoicedQty);

        if (pendingQty > 0) {
          enrichedItems.push({
            ...item,
            quantity: pendingQty,
          });
        }
      }

      const total_items = formattedItems.length;
      const pending_items = enrichedItems.length;
      const invoiced_items = total_items - pending_items;
      const completion_percentage =
        total_items > 0 ? Math.round((invoiced_items / total_items) * 100) : 0;

      enrichedOrders.push({
        ...order,
        items: enrichedItems,
        total_items,
        invoiced_items,
        pending_items,
        completion_percentage,
      });
    }

    return enrichedOrders;
  }

  async getPayments(orgId?: string) {
    let sqlQuery = `SELECT * FROM sales_payments`;
    const params: any[] = [];
    if (orgId) {
      params.push(orgId);
      sqlQuery += ` WHERE entity_id = $1`;
    }
    sqlQuery += ` ORDER BY created_at DESC`;

    const data = await client.unsafe(sqlQuery, params);
    return data ?? [];
  }

  async createPayment(body: any, orgId: string) {
    const payload = {
      ...body,
      entity_id: body?.entity_id ?? orgId,
      created_at: body?.created_at ?? new Date().toISOString(),
      updated_at: body?.updated_at ?? new Date().toISOString(),
    };

    const keys = Object.keys(payload);
    const cols = keys.map((k) => `"${k}"`).join(", ");
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");
    const values: any[] = Object.values(payload);

    const rows = await client.unsafe(
      `INSERT INTO sales_payments (${cols}) VALUES (${placeholders}) RETURNING *`,
      values,
    );

    return rows[0];
  }

  async getPaymentLinks(orgId?: string) {
    let sqlQuery = `SELECT * FROM sales_payment_links`;
    const params: any[] = [];
    if (orgId) {
      params.push(orgId);
      sqlQuery += ` WHERE entity_id = $1`;
    }
    sqlQuery += ` ORDER BY created_at DESC`;

    const data = await client.unsafe(sqlQuery, params);
    return data ?? [];
  }

  async createPaymentLink(body: any, orgId: string) {
    const payload = {
      ...body,
      entity_id: body?.entity_id ?? orgId,
      created_at: body?.created_at ?? new Date().toISOString(),
      updated_at: body?.updated_at ?? new Date().toISOString(),
    };

    const keys = Object.keys(payload);
    const cols = keys.map((k) => `"${k}"`).join(", ");
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");
    const values: any[] = Object.values(payload);

    const rows = await client.unsafe(
      `INSERT INTO sales_payment_links (${cols}) VALUES (${placeholders}) RETURNING *`,
      values,
    );

    return rows[0];
  }

  async getEWayBills(orgId?: string) {
    let sqlQuery = `SELECT * FROM sales_eway_bills`;
    const params: any[] = [];
    if (orgId) {
      params.push(orgId);
      sqlQuery += ` WHERE entity_id = $1`;
    }
    sqlQuery += ` ORDER BY created_at DESC`;

    const data = await client.unsafe(sqlQuery, params);
    return data ?? [];
  }

  async createEWayBill(body: any, orgId: string) {
    const payload = {
      ...body,
      entity_id: body?.entity_id ?? orgId,
      created_at: body?.created_at ?? new Date().toISOString(),
      updated_at: body?.updated_at ?? new Date().toISOString(),
    };

    const keys = Object.keys(payload);
    const cols = keys.map((k) => `"${k}"`).join(", ");
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");
    const values: any[] = Object.values(payload);

    const rows = await client.unsafe(
      `INSERT INTO sales_eway_bills (${cols}) VALUES (${placeholders}) RETURNING *`,
      values,
    );

    return rows[0];
  }

  async createSalesOrder(body: any, orgId: string) {
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
      const assocTaxes = await client.unsafe(
        `SELECT id, tax_rate FROM tax_rates WHERE id = ANY($1)`,
        [taxIdSet],
      );

      for (const t of assocTaxes ?? []) {
        taxResolutionMap.set(t.id, {
          tax_id: t.id,
          tax_rate: Number(t.tax_rate),
        });
      }

      const unresolved = taxIdSet.filter((id) => !taxResolutionMap.has(id));
      if (unresolved.length > 0) {
        const groups = await client.unsafe(
          `SELECT id, tax_rate FROM tax_groups WHERE id = ANY($1)`,
          [unresolved],
        );
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

    const createdOrders = await client.unsafe(
      `INSERT INTO sales_orders (
        entity_id, customer_id, sale_number, reference, sale_date, expected_shipment_date,
        payment_term_id, delivery_method, salesperson_name, status, document_type,
        sub_total, tax_total, discount_total, shipping_charges, adjustment, total_quantity,
        total, customer_notes, terms_and_conditions, warehouse_id, price_list_id,
        place_of_supply, gst_treatment, tds_tcs_type, tds_tcs_tax_id, tds_tcs_amount, is_delete
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, false)
      RETURNING *`,
      [
        orgId,
        customerId,
        sanitizedSaleNumber,
        reference || null,
        saleDate || new Date().toISOString(),
        expectedShipmentDate || null,
        paymentTerms || null,
        deliveryMethod || null,
        salesperson || null,
        status || "Draft",
        documentType,
        finalSubTotal,
        finalTaxTotal,
        computedDiscountTotal,
        finalShipping,
        finalAdjustment,
        computedTotalQuantity,
        finalTotal,
        customerNotes || null,
        termsAndConditions || null,
        warehouseId || null,
        priceListId || null,
        placeOfSupply || null,
        gstTreatment || null,
        sanitizedTdsTcsType,
        tdsTcsTaxId || null,
        tdsTcsAmount ? Number(tdsTcsAmount) : 0,
      ],
    );

    const order = createdOrders[0];
    if (!order) throw new Error("Failed to create sales order");

    if (processedItems.length > 0) {
      try {
        for (const item of processedItems) {
          await client.unsafe(
            `INSERT INTO sales_order_items (
              entity_id, sales_order_id, line_no, product_id, description, quantity, rate,
              discount_type, discount_value, discount_amount, tax_id, tax_rate, tax_amount,
              amount, hsn_code, accounts, pricelist, warehouse_id, is_invoiced
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)`,
            [
              item.entity_id,
              order.id,
              item.line_no,
              item.product_id,
              item.description,
              item.quantity,
              item.rate,
              item.discount_type,
              item.discount_value,
              item.discount_amount,
              item.tax_id,
              item.tax_rate,
              item.tax_amount,
              item.amount,
              item.hsn_code,
              item.accounts,
              item.pricelist,
              item.warehouse_id,
              item.is_invoiced,
            ],
          );
        }
      } catch (itemsError) {
        await client.unsafe(`DELETE FROM sales_orders WHERE id = $1`, [order.id]);
        throw itemsError;
      }
    }

    return order;
  }

  async updateSalesOrder(id: string, body: any, orgId: string) {
    const existing = await client.unsafe(
      `SELECT id, document_type FROM sales_orders WHERE id = $1 AND entity_id = $2 LIMIT 1`,
      [id, orgId],
    );

    if (!existing[0])
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
      documentType = existing[0].document_type,
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
      const assocTaxes = await client.unsafe(
        `SELECT id, tax_rate FROM tax_rates WHERE id = ANY($1)`,
        [taxIdSet],
      );

      for (const t of assocTaxes ?? []) {
        taxResolutionMap.set(t.id, {
          tax_id: t.id,
          tax_rate: Number(t.tax_rate),
        });
      }

      const unresolved = taxIdSet.filter((id) => !taxResolutionMap.has(id));
      if (unresolved.length > 0) {
        const groups = await client.unsafe(
          `SELECT id, tax_rate FROM tax_groups WHERE id = ANY($1)`,
          [unresolved],
        );
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

    const updatedOrders = await client.unsafe(
      `UPDATE sales_orders SET
         customer_id = $1, sale_number = $2, reference = $3, sale_date = $4,
         expected_shipment_date = $5, payment_term_id = $6, delivery_method = $7,
         salesperson_name = $8, status = $9, sub_total = $10, tax_total = $11,
         discount_total = $12, shipping_charges = $13, adjustment = $14,
         total_quantity = $15, total = $16, customer_notes = $17, terms_and_conditions = $18,
         warehouse_id = $19, price_list_id = $20, place_of_supply = $21, gst_treatment = $22,
         tds_tcs_type = $23, tds_tcs_tax_id = $24, tds_tcs_amount = $25, updated_at = NOW()
       WHERE id = $26 AND entity_id = $27
       RETURNING *`,
      [
        customerId,
        sanitizedSaleNumber,
        reference || null,
        saleDate || null,
        expectedShipmentDate || null,
        paymentTerms || null,
        deliveryMethod || null,
        salesperson || null,
        status || "Draft",
        finalSubTotal,
        finalTaxTotal,
        computedDiscountTotal,
        finalShipping,
        finalAdjustment,
        computedTotalQuantity,
        finalTotal,
        customerNotes || null,
        termsAndConditions || null,
        warehouseId || null,
        priceListId || null,
        placeOfSupply || null,
        gstTreatment || null,
        sanitizedTdsTcsType,
        tdsTcsTaxId || null,
        tdsTcsAmount ? Number(tdsTcsAmount) : 0,
        id,
        orgId,
      ],
    );

    const order = updatedOrders[0];
    if (!order) throw new Error("Failed to update sales order");

    await client.unsafe(
      `DELETE FROM sales_order_items WHERE sales_order_id = $1 AND entity_id = $2`,
      [id, orgId],
    );

    if (processedItems.length > 0) {
      for (const item of processedItems) {
        await client.unsafe(
          `INSERT INTO sales_order_items (
            entity_id, sales_order_id, line_no, product_id, description, quantity, rate,
            discount_type, discount_value, discount_amount, tax_id, tax_rate, tax_amount,
            amount, hsn_code, accounts, pricelist, warehouse_id, is_invoiced
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)`,
          [
            item.entity_id,
            item.sales_order_id,
            item.line_no,
            item.product_id,
            item.description,
            item.quantity,
            item.rate,
            item.discount_type,
            item.discount_value,
            item.discount_amount,
            item.tax_id,
            item.tax_rate,
            item.tax_amount,
            item.amount,
            item.hsn_code,
            item.accounts,
            item.pricelist,
            item.warehouse_id,
            item.is_invoiced,
          ],
        );
      }
    }

    return order;
  }

  async getInvoices(orgId: string) {
    const invoices = await client.unsafe(
      `SELECT * FROM invoice_master WHERE entity_id = $1 AND (is_delete IS NULL OR is_delete = false) ORDER BY created_at DESC`,
      [orgId],
    );

    if (!invoices || invoices.length === 0) return [];

    const customerIds = Array.from(
      new Set(invoices.map((inv: any) => inv.customer_id).filter(Boolean)),
    );

    const customersMap = new Map<string, any>();
    if (customerIds.length > 0) {
      const customersData = await client.unsafe(
        `SELECT id, display_name, first_name, last_name, company_name FROM customers WHERE id = ANY($1)`,
        [customerIds],
      );

      if (customersData) {
        for (const customer of customersData) {
          customersMap.set(customer.id, customer);
        }
      }
    }

    const invoiceIds = invoices.map((inv: any) => inv.id);
    const invoiceSoMap = new Map<string, { order_number: string; sales_order_id: string }>();
    try {
      if (invoiceIds.length > 0) {
        const linkedLinks = await client.unsafe(
          `SELECT invoice_id, sales_order_id FROM invoice_sales_orders WHERE invoice_id = ANY($1)`,
          [invoiceIds],
        );

        if (linkedLinks && linkedLinks.length > 0) {
          const soIds = Array.from(new Set(linkedLinks.map((l: any) => l.sales_order_id)));
          const sos = await client.unsafe(
            `SELECT id, sale_number FROM sales_orders WHERE id = ANY($1)`,
            [soIds],
          );

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

    return invoices.map((inv: any) => ({
      ...inv,
      customer: inv.customer_id
        ? customersMap.get(inv.customer_id) || null
        : null,
      order_number: invoiceSoMap.get(inv.id)?.order_number || null,
      sales_order_id: invoiceSoMap.get(inv.id)?.sales_order_id || null,
    }));
  }

  async getInvoiceById(id: string, orgId: string) {
    const invoices = await client.unsafe(
      `SELECT * FROM invoice_master WHERE entity_id = $1 AND id = $2 LIMIT 1`,
      [orgId, id],
    );

    const invoice = invoices[0];
    if (!invoice) throw new NotFoundException(`Invoice ${id} not found`);

    let customer: any = null;
    if (invoice?.customer_id) {
      const customers = await client.unsafe(
        `SELECT id, display_name, first_name, last_name, company_name FROM customers WHERE id = $1 LIMIT 1`,
        [invoice.customer_id],
      );

      if (customers[0]) {
        customer = { ...customers[0] };
        const addresses = await client.unsafe(
          `SELECT * FROM customer_addresses WHERE customer_id = $1 AND is_active = true`,
          [invoice.customer_id],
        );

        if (addresses) {
          const billing = addresses.find((a: any) => a.is_default_billing) ||
                          addresses.find((a: any) => a.address_type === "billing");
          if (billing) {
            customer.billing_address_street_1 = billing.address_street;
            customer.billing_address_street_2 = billing.address_place;
            customer.billing_address_city = billing.city;
            customer.billing_address_zip = billing.pincode;
            customer.billing_address_state_id = billing.state;
            customer.billing_address_country_id = billing.country_region;
            customer.billing_address_phone = billing.phone;
          }
          const shipping = addresses.find((a: any) => a.is_default_shipping) ||
                           addresses.find((a: any) => a.address_type === "shipping");
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

    const items = await client.unsafe(
      `SELECT * FROM invoice_items WHERE invoice_id = $1`,
      [id],
    );

    const productIds = (items || [])
      .map((item: any) => item.product_id)
      .filter(Boolean);
    const productMap = new Map<string, any>();
    if (productIds.length > 0) {
      const productsData = await client.unsafe(
        `SELECT p.id, p.product_name, p.sku, p.item_code, p.unit_id, p.hsn_sac_code as hsn_code, p.sales_account_id, u.unit_name
         FROM products p
         LEFT JOIN units u ON u.id = p.unit_id
         WHERE p.id = ANY($1)`,
        [productIds],
      );

      if (productsData) {
        for (const p of productsData) {
          productMap.set(p.id, {
            ...p,
            unit: p.unit_name ? { unit_name: p.unit_name } : null,
          });
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

      try {
        const batches = await client.unsafe(
          `SELECT iib.*, bm.batch_no, bm.expiry_date, bm.unit_pack, bm.manufacture_batch_number, bm.manufacture_exp
           FROM invoice_item_batches iib
           LEFT JOIN batch_master bm ON bm.id = iib.batch_id
           WHERE iib.invoice_item_id = $1`,
          [item.id],
        );

        let enrichedBatches = (batches ?? []).map((b: any) => ({
          ...b,
          batch: b.batch_id
            ? {
                id: b.batch_id,
                batch_no: b.batch_no,
                expiry_date: b.expiry_date,
                unit_pack: b.unit_pack,
                manufacture_batch_number: b.manufacture_batch_number,
                manufacture_exp: b.manufacture_exp,
              }
            : null,
        }));

        if (enrichedBatches.length > 0) {
          const binIds = enrichedBatches.map((b: any) => b.bin_id).filter(Boolean);
          if (binIds.length > 0) {
            const bins = await client.unsafe(
              `SELECT id, bin_code FROM bin_master WHERE id = ANY($1)`,
              [binIds],
            );

            if (bins) {
              const binMap = new Map(bins.map((b: any) => [b.id, b]));
              enrichedBatches = enrichedBatches.map((b: any) => ({
                ...b,
                bin: b.bin_id ? binMap.get(b.bin_id) || null : null,
              }));
            }
          }
        }

        enrichedItems.push({
          ...enrichedItem,
          batches: enrichedBatches,
        });
      } catch {
        enrichedItems.push(enrichedItem);
      }
    }

    let orderNumber: string | null = null;
    let salesOrderId: string | null = null;
    try {
      const linked = await client.unsafe(
        `SELECT sales_order_id FROM invoice_sales_orders WHERE invoice_id = $1 LIMIT 1`,
        [id],
      );

      if (linked[0]?.sales_order_id) {
        salesOrderId = linked[0].sales_order_id;
        const so = await client.unsafe(
          `SELECT sale_number FROM sales_orders WHERE id = $1 LIMIT 1`,
          [salesOrderId],
        );
        if (so[0]) {
          orderNumber = so[0].sale_number;
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

    const isBatchAllocated = resolvedItems.some(
      (i: any) => i.batches && i.batches.length > 0,
    );

    const finalSubtotal = Number(subtotal) || 0;
    const finalShipping = Number(shippingCharges) || 0;
    const finalAdjustment = Number(adjustmentAmount) || 0;
    const finalRoundOff = Number(roundOff) || 0;
    const finalTaxTotal = isUnregistered ? 0 : (Number(taxTotal) || 0);
    const finalGrandTotal = isUnregistered
      ? finalSubtotal + finalShipping + finalAdjustment + finalRoundOff
      : (Number(grandTotal) || 0);

    const invoiceRows = await client.unsafe(
      `INSERT INTO invoice_master (
        entity_id, customer_id, invoice_number, invoice_date, due_date, payment_terms,
        salesperson_id, subject, customer_notes, terms_conditions, price_list_id, warehouse_id,
        place_of_supply, gst_treatment, shipping_charges, adjustment_amount, round_off,
        subtotal, tax_total, tds_total, tcs_total, grand_total, inventory_flow_type,
        status, is_batch_allocated, is_delete
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, false)
      RETURNING *`,
      [
        orgId,
        customerId,
        invoiceNumber,
        invoiceDate,
        dueDate || null,
        paymentTerms || null,
        salespersonId || null,
        subject || null,
        customerNotes || null,
        termsConditions || null,
        priceListId || null,
        warehouseId || null,
        placeOfSupply || null,
        gstTreatment || null,
        finalShipping,
        finalAdjustment,
        finalRoundOff,
        finalSubtotal,
        finalTaxTotal,
        Number(tdsTotal) || 0,
        Number(tcsTotal) || 0,
        finalGrandTotal,
        inventoryFlowType || "DIRECT_INVOICE",
        status || "draft",
        isBatchAllocated,
      ],
    );

    const invoice = invoiceRows[0];
    if (!invoice) throw new Error("Failed to create invoice");

    let originalSalesOrderStatus = "confirmed";
    let originalSalesOrderItemsState: any[] = [];
    const updatedLayers: { layerId: string; quantityAdded: number }[] = [];

    try {
      if (salesOrderId) {
        const soRows = await client.unsafe(
          `SELECT status FROM sales_orders WHERE id = $1 AND entity_id = $2 LIMIT 1`,
          [salesOrderId, orgId],
        );
        if (soRows[0]) {
          originalSalesOrderStatus = soRows[0].status;
        }

        const soItems = await client.unsafe(
          `SELECT * FROM sales_order_items WHERE sales_order_id = $1 AND entity_id = $2`,
          [salesOrderId, orgId],
        );

        if (soItems && soItems.length > 0) {
          originalSalesOrderItemsState = soItems.map((item: any) => ({
            id: item.id,
            is_invoiced: item.is_invoiced,
          }));

          const linkedInvoices = await client.unsafe(
            `SELECT invoice_id FROM invoice_sales_orders WHERE sales_order_id = $1`,
            [salesOrderId],
          );

          const invoiceIds = (linkedInvoices ?? []).map(
            (li: any) => li.invoice_id,
          );
          const invoicedQuantities = new Map<string, number>();

          if (invoiceIds.length > 0) {
            const invItems = await client.unsafe(
              `SELECT product_id, quantity FROM invoice_items WHERE invoice_id = ANY($1)`,
              [invoiceIds],
            );

            for (const item of invItems ?? []) {
              const current = invoicedQuantities.get(item.product_id) || 0;
              invoicedQuantities.set(
                item.product_id,
                current + Number(item.quantity),
              );
            }
          }

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

          await client.unsafe(
            `INSERT INTO invoice_sales_orders (invoice_id, sales_order_id) VALUES ($1, $2)`,
            [invoice.id, salesOrderId],
          );

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

            await client.unsafe(
              `UPDATE sales_order_items SET is_invoiced = $1 WHERE id = $2 AND entity_id = $3`,
              [isFullyInvoiced, soItem.id, orgId],
            );

            soItem.is_invoiced = isFullyInvoiced;
          }

          const allInvoiced = soItems.every(
            (item: any) =>
              item.is_invoiced === true || item.is_invoiced === "true",
          );
          if (allInvoiced) {
            await client.unsafe(
              `UPDATE sales_orders SET status = 'closed' WHERE id = $1 AND entity_id = $2`,
              [salesOrderId, orgId],
            );
          }
        }
      }

      if (packageId) {
        await client.unsafe(
          `INSERT INTO invoice_packages (invoice_id, package_id) VALUES ($1, $2)`,
          [invoice.id, packageId],
        );
      }

      for (const item of resolvedItems) {
        const itemRows = await client.unsafe(
          `INSERT INTO invoice_items (
            invoice_id, product_id, description, quantity, rate, discount_type, discount_value,
            tax_id, tax_percentage, taxable_amount, tax_amount, line_total, foc_quantity, hsn_code, accounts
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
          RETURNING *`,
          [
            invoice.id,
            item.productId || item.itemId,
            item.description || null,
            Number(item.quantity) || 0,
            Number(item.rate) || 0,
            item.discountType || null,
            Number(item.discountValue) || 0,
            isUnregistered ? null : (item.taxId || null),
            isUnregistered ? 0 : (Number(item.taxPercentage) || 0),
            Number(item.taxableAmount) || 0,
            isUnregistered ? 0 : (Number(item.taxAmount) || 0),
            isUnregistered ? (Number(item.taxableAmount) || 0) : (Number(item.lineTotal) || 0),
            Number(item.focQuantity) || 0,
            item.hsnCode || "0",
            item.accounts || null,
          ],
        );

        const insertedItem = itemRows[0];

        if (item.batches && item.batches.length > 0) {
          for (const batch of item.batches) {
            const qty = Number(batch.quantity) || 0;
            const focQty = Number(batch.focQuantity) || 0;
            const totalOutQty = qty + focQty;

            await client.unsafe(
              `INSERT INTO invoice_item_batches (
                invoice_item_id, batch_id, layer_id, warehouse_id, bin_id, quantity, foc_quantity,
                purchase_rate, sales_rate, mrp, expiry_date, manufacturer_batch
              ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
              [
                insertedItem.id,
                batch.batchId,
                batch.layerId || null,
                batch.warehouseId || warehouseId,
                batch.binId || null,
                qty,
                focQty,
                batch.purchaseRate ? Number(batch.purchaseRate) : null,
                batch.salesRate ? Number(batch.salesRate) : null,
                batch.mrp ? Number(batch.mrp) : null,
                this.parseToIsoDate(batch.expiryDate),
                batch.manufacturerBatch || null,
              ],
            );

            await client.unsafe(
              `INSERT INTO batch_transactions (
                batch_id, layer_id, product_id, entity_id, warehouse_id, bin_id, trans_type,
                stock_effect_type, ref_id, ref_no, qty_in, qty_out, rate, trans_date
              ) VALUES ($1, $2, $3, $4, $5, $6, 'INVOICE', 'ACCOUNTING', $7, $8, 0, $9, $10, $11)`,
              [
                batch.batchId,
                batch.layerId || null,
                item.productId || item.itemId,
                orgId,
                batch.warehouseId || warehouseId,
                batch.binId || null,
                invoice.id,
                invoiceNumber,
                totalOutQty,
                batch.salesRate ? Number(batch.salesRate) : null,
                invoiceDate,
              ],
            );

            if (!packageId && batch.layerId) {
              const layerRows = await client.unsafe(
                `SELECT qty FROM batch_stock_layers WHERE id = $1 LIMIT 1`,
                [batch.layerId],
              );

              if (layerRows[0]) {
                const currentQty = Number(layerRows[0].qty) || 0;
                const newQty = Math.max(0, currentQty - totalOutQty);

                await client.unsafe(
                  `UPDATE batch_stock_layers SET qty = $1 WHERE id = $2`,
                  [newQty, batch.layerId],
                );

                updatedLayers.push({
                  layerId: batch.layerId,
                  quantityAdded: totalOutQty,
                });
              }
            }
          }
        }
      }

      await this.postInvoiceTransactions(tenant || ({ entityId: orgId, userId: body.user_id || body.userId } as any), invoice, body);

      return invoice;
    } catch (error) {
      try {
        await client.unsafe(`DELETE FROM invoice_master WHERE id = $1 AND entity_id = $2`, [invoice.id, orgId]);

        if (salesOrderId) {
          await client.unsafe(
            `UPDATE sales_orders SET status = $1 WHERE id = $2 AND entity_id = $3`,
            [originalSalesOrderStatus, salesOrderId, orgId],
          );

          for (const itemState of originalSalesOrderItemsState) {
            await client.unsafe(
              `UPDATE sales_order_items SET is_invoiced = $1 WHERE id = $2 AND entity_id = $3`,
              [itemState.is_invoiced, itemState.id, orgId],
            );
          }
        }

        for (const layerUpdate of updatedLayers) {
          const currentLayers = await client.unsafe(
            `SELECT qty FROM batch_stock_layers WHERE id = $1 LIMIT 1`,
            [layerUpdate.layerId],
          );
          if (currentLayers[0]) {
            const currentQty = Number(currentLayers[0].qty) || 0;
            await client.unsafe(
              `UPDATE batch_stock_layers SET qty = $1 WHERE id = $2`,
              [currentQty + layerUpdate.quantityAdded, layerUpdate.layerId],
            );
          }
        }
      } catch (rollbackError) {
        console.error("Rollback failed:", rollbackError);
      }
      throw error;
    }
  }

  async updateInvoice(id: string, body: any, orgId: string, tenant?: TenantContext) {
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

    const oldTx = await client.unsafe(
      `SELECT * FROM batch_transactions WHERE ref_id = $1 AND entity_id = $2 AND trans_type = 'INVOICE'`,
      [id, orgId],
    );

    const revertedLayers: { layerId: string; quantitySubtracted: number }[] = [];
    try {
      if (oldTx && oldTx.length > 0) {
        for (const tx of oldTx) {
          if (tx.layer_id && tx.qty_out) {
            const layerRows = await client.unsafe(
              `SELECT qty FROM batch_stock_layers WHERE id = $1 LIMIT 1`,
              [tx.layer_id],
            );
            if (layerRows[0]) {
              const currentQty = Number(layerRows[0].qty) || 0;
              const txQty = Number(tx.qty_out) || 0;
              await client.unsafe(
                `UPDATE batch_stock_layers SET qty = $1 WHERE id = $2`,
                [currentQty + txQty, tx.layer_id],
              );
              revertedLayers.push({ layerId: tx.layer_id, quantitySubtracted: txQty });
            }
          }
        }
      }

      await client.unsafe(
        `DELETE FROM batch_transactions WHERE ref_id = $1 AND entity_id = $2 AND trans_type = 'INVOICE'`,
        [id, orgId],
      );

      await client.unsafe(`DELETE FROM invoice_items WHERE invoice_id = $1`, [id]);

      const isUnregistered =
        gstTreatment?.toLowerCase() === "unregistered_business" ||
        gstTreatment?.toLowerCase() === "unregistered business";

      const isBatchAllocated = resolvedItems.some(
        (i: any) => i.batches && i.batches.length > 0,
      );

      const finalSubtotal = Number(subtotal) || 0;
      const finalShipping = Number(shippingCharges) || 0;
      const finalAdjustment = Number(adjustmentAmount) || 0;
      const finalRoundOff = Number(roundOff) || 0;
      const finalTaxTotal = isUnregistered ? 0 : (Number(taxTotal) || 0);
      const finalGrandTotal = isUnregistered
        ? finalSubtotal + finalShipping + finalAdjustment + finalRoundOff
        : (Number(grandTotal) || 0);

      const updatedInvoices = await client.unsafe(
        `UPDATE invoice_master SET
           customer_id = $1, invoice_number = $2, invoice_date = $3, due_date = $4,
           payment_terms = $5, salesperson_id = $6, subject = $7, customer_notes = $8,
           terms_conditions = $9, price_list_id = $10, warehouse_id = $11, place_of_supply = $12,
           gst_treatment = $13, shipping_charges = $14, adjustment_amount = $15, round_off = $16,
           subtotal = $17, tax_total = $18, tds_total = $19, tcs_total = $20, grand_total = $21,
           inventory_flow_type = $22, status = $23, is_batch_allocated = $24, updated_at = NOW()
         WHERE id = $25 AND entity_id = $26
         RETURNING *`,
        [
          customerId,
          invoiceNumber,
          invoiceDate,
          dueDate || null,
          paymentTerms || null,
          salespersonId || null,
          subject || null,
          customerNotes || null,
          termsConditions || null,
          priceListId || null,
          warehouseId || null,
          placeOfSupply || null,
          gstTreatment || null,
          finalShipping,
          finalAdjustment,
          finalRoundOff,
          finalSubtotal,
          finalTaxTotal,
          Number(tdsTotal) || 0,
          Number(tcsTotal) || 0,
          finalGrandTotal,
          inventoryFlowType || "DIRECT_INVOICE",
          status || "draft",
          isBatchAllocated,
          id,
          orgId,
        ],
      );

      const invoice = updatedInvoices[0];
      if (!invoice) throw new Error("Failed to update invoice");

      for (const item of resolvedItems) {
        const itemRows = await client.unsafe(
          `INSERT INTO invoice_items (
            invoice_id, product_id, description, quantity, rate, discount_type, discount_value,
            tax_id, tax_percentage, taxable_amount, tax_amount, line_total, foc_quantity, hsn_code, accounts
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
          RETURNING *`,
          [
            id,
            item.productId || item.itemId,
            item.description || null,
            Number(item.quantity) || 0,
            Number(item.rate) || 0,
            item.discountType || null,
            Number(item.discountValue) || 0,
            isUnregistered ? null : (item.taxId || null),
            isUnregistered ? 0 : (Number(item.taxPercentage) || 0),
            Number(item.taxableAmount) || 0,
            isUnregistered ? 0 : (Number(item.taxAmount) || 0),
            isUnregistered ? (Number(item.taxableAmount) || 0) : (Number(item.lineTotal) || 0),
            Number(item.focQuantity) || 0,
            item.hsnCode || "0",
            item.accounts || null,
          ],
        );

        const insertedItem = itemRows[0];

        if (item.batches && item.batches.length > 0) {
          for (const batch of item.batches) {
            const qty = Number(batch.quantity) || 0;
            const focQty = Number(batch.focQuantity) || 0;
            const totalOutQty = qty + focQty;

            await client.unsafe(
              `INSERT INTO invoice_item_batches (
                invoice_item_id, batch_id, layer_id, warehouse_id, bin_id, quantity, foc_quantity,
                purchase_rate, sales_rate, mrp, expiry_date, manufacturer_batch
              ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
              [
                insertedItem.id,
                batch.batchId,
                batch.layerId || null,
                batch.warehouseId || warehouseId,
                batch.binId || null,
                qty,
                focQty,
                batch.purchaseRate ? Number(batch.purchaseRate) : null,
                batch.salesRate ? Number(batch.salesRate) : null,
                batch.mrp ? Number(batch.mrp) : null,
                this.parseToIsoDate(batch.expiryDate),
                batch.manufacturerBatch || null,
              ],
            );

            await client.unsafe(
              `INSERT INTO batch_transactions (
                batch_id, layer_id, product_id, entity_id, warehouse_id, bin_id, trans_type,
                stock_effect_type, ref_id, ref_no, qty_in, qty_out, rate, trans_date
              ) VALUES ($1, $2, $3, $4, $5, $6, 'INVOICE', 'ACCOUNTING', $7, $8, 0, $9, $10, $11)`,
              [
                batch.batchId,
                batch.layerId || null,
                item.productId || item.itemId,
                orgId,
                batch.warehouseId || warehouseId,
                batch.binId || null,
                id,
                invoiceNumber,
                totalOutQty,
                batch.salesRate ? Number(batch.salesRate) : null,
                invoiceDate,
              ],
            );

            if (batch.layerId) {
              const layerRows = await client.unsafe(
                `SELECT qty FROM batch_stock_layers WHERE id = $1 LIMIT 1`,
                [batch.layerId],
              );
              if (layerRows[0]) {
                const currentQty = Number(layerRows[0].qty) || 0;
                const newQty = currentQty - totalOutQty;

                await client.unsafe(
                  `UPDATE batch_stock_layers SET qty = $1 WHERE id = $2`,
                  [newQty, batch.layerId],
                );
              }
            }
          }
        }
      }

      await this.postInvoiceTransactions(tenant || ({ entityId: orgId, userId: body.user_id || body.userId } as any), invoice, body);

      return invoice;
    } catch (error) {
      try {
        for (const layerRevert of revertedLayers) {
          const currentLayers = await client.unsafe(
            `SELECT qty FROM batch_stock_layers WHERE id = $1 LIMIT 1`,
            [layerRevert.layerId],
          );
          if (currentLayers[0]) {
            const currentQty = Number(currentLayers[0].qty) || 0;
            await client.unsafe(
              `UPDATE batch_stock_layers SET qty = $1 WHERE id = $2`,
              [currentQty - layerRevert.quantitySubtracted, layerRevert.layerId],
            );
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

    const branches = await client.unsafe(
      `SELECT id, name, ref_id FROM organisation_branch_master WHERE parent_id = $1 AND type = 'BRANCH'`,
      [targetOrgId],
    );

    if (!branches || branches.length === 0) {
      return [];
    }

    const branchEntityIds = branches.map((b: any) => b.id);
    const branchNameMap = new Map<string, string>();
    const branchRefMap = new Map<string, string>();
    for (const b of branches) {
      branchNameMap.set(b.id, b.name);
      if (b.ref_id) {
        branchRefMap.set(b.id, b.ref_id);
      }
    }

    const branchRefIds = branches.map((b: any) => b.ref_id).filter(Boolean);
    const branchCreditLimitMap = new Map<string, number>();
    if (branchRefIds.length > 0) {
      const custs = await client.unsafe(
        `SELECT associated_branch_id, credit_limit FROM customers WHERE associated_branch_id = ANY($1) AND entity_id = $2`,
        [branchRefIds, targetOrgId],
      );
      if (custs) {
        for (const c of custs) {
          if (c.associated_branch_id) {
            branchCreditLimitMap.set(
              c.associated_branch_id,
              c.credit_limit ? parseFloat(c.credit_limit.toString()) : 0.0,
            );
          }
        }
      }
    }

    const pos = await client.unsafe(
      `SELECT id, order_number, order_date, status, warehouse_id, total, entity_id
       FROM purchase_orders
       WHERE entity_id = ANY($1) AND vendor_id = 'db013159-6ac3-49a6-95b1-eaec10f964db' AND status != 'Draft' AND is_delete = false
       ORDER BY order_date DESC`,
      [branchEntityIds],
    );

    if (!pos || pos.length === 0) {
      return [];
    }

    const warehouseIds = pos.map((p: any) => p.warehouse_id).filter(Boolean);
    const warehouseNameMap = new Map<string, string>();
    if (warehouseIds.length > 0) {
      const whs = await client.unsafe(
        `SELECT id, name FROM warehouses WHERE id = ANY($1)`,
        [warehouseIds],
      );
      if (whs) {
        for (const w of whs) {
          warehouseNameMap.set(w.id, w.name);
        }
      }
    }

    const poNumbers = pos.map((p: any) => p.order_number).filter(Boolean);
    let usedPoIds: string[] = [];

    if (poNumbers.length > 0) {
      const sos = await client.unsafe(
        `SELECT id, reference, sale_date, created_at, status FROM sales_orders WHERE entity_id = $1 AND reference = ANY($2) AND status != 'void'`,
        [targetOrgId, poNumbers],
      );

      if (sos && sos.length > 0) {
        for (const po of pos) {
          const poDate = new Date(po.order_date);
          const poDateBuffer = new Date(poDate.getTime() - 24 * 60 * 60 * 1000);

          const isApproved = sos.some((so: any) => {
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

    const filteredPos = pos.filter((po: any) => !usedPoIds.includes(po.id));

    const result = filteredPos.map((po: any) => {
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
    const starlexOrgEntityId = "66d79887-be98-40ab-ac40-9e0a008f9d8a";
    const targetOrgId = (tenant.entityId && tenant.entityId !== "00000000-0000-0000-0000-000000000002")
      ? tenant.entityId
      : starlexOrgEntityId;

    const defaultSalesAccountId = await this.resolveDefaultSalesAccountId(targetOrgId);

    const results = [];
    for (const poId of poIds) {
      const pos = await client.unsafe(
        `SELECT * FROM purchase_orders WHERE id = $1 LIMIT 1`,
        [poId],
      );

      const po = pos[0];
      if (!po) {
        throw new NotFoundException(`Purchase Order ${poId} not found`);
      }

      const poItems = await client.unsafe(
        `SELECT * FROM purchase_order_items WHERE purchase_order_id = $1`,
        [poId],
      );
      po.items = poItems ?? [];

      const poDate = new Date(po.order_date);
      const poDateBuffer = new Date(poDate.getTime() - 24 * 60 * 60 * 1000).toISOString();

      const existingSos = await client.unsafe(
        `SELECT id FROM sales_orders WHERE entity_id = $1 AND reference = $2 AND created_at >= $3 AND status != 'void' LIMIT 1`,
        [targetOrgId, po.order_number, poDateBuffer],
      );

      if (existingSos[0]) {
        results.push({ poId, status: "already_approved", salesOrderId: existingSos[0].id });
        continue;
      }

      const branches = await client.unsafe(
        `SELECT id, name, ref_id FROM organisation_branch_master WHERE id = $1 LIMIT 1`,
        [po.entity_id],
      );

      const branch = branches[0];
      let customerId: string | null = null;
      if (branch && branch.ref_id) {
        const custs = await client.unsafe(
          `SELECT id FROM customers WHERE associated_branch_id = $1 AND entity_id = $2 LIMIT 1`,
          [branch.ref_id, starlexOrgEntityId],
        );
        if (custs[0]) {
          customerId = custs[0].id;
        }
      }

      if (!customerId) {
        const custs = await client.unsafe(
          `SELECT id, display_name FROM customers WHERE entity_id = $1`,
          [starlexOrgEntityId],
        );

        if (custs && custs.length > 0) {
          const match = branch ? custs.find((c: any) => c.display_name.toLowerCase().includes(branch.name.toLowerCase())) : null;
          customerId = match ? match.id : custs[0].id;
        }
      }

      if (!customerId) {
        throw new BadRequestException(`No customer record found for branch ${branch?.name ?? po.entity_id}`);
      }

      const productIds = (po.items || []).map((item: any) => item.product_id).filter(Boolean);
      const productMap = new Map<string, string>();
      if (productIds.length > 0) {
        const productsData = await client.unsafe(
          `SELECT id, sales_account_id FROM products WHERE id = ANY($1)`,
          [productIds],
        );
        if (productsData) {
          for (const p of productsData) {
            if (p.sales_account_id) {
              productMap.set(p.id, p.sales_account_id);
            }
          }
        }
      }

      const poTaxIds = (po.items || []).map((item: any) => item.tax_id).filter(Boolean);
      const validTaxIds = new Set<string>();
      if (poTaxIds.length > 0) {
        const taxRatesData = await client.unsafe(
          `SELECT id FROM tax_rates WHERE id = ANY($1)`,
          [poTaxIds],
        );
        if (taxRatesData) {
          for (const tr of taxRatesData) {
            validTaxIds.add(tr.id);
          }
        }
      }

      const maxSo = await client.unsafe(
        `SELECT sale_number FROM sales_orders WHERE entity_id = $1 AND sale_number LIKE 'SO-%'`,
        [starlexOrgEntityId],
      );

      let maxNum = 0;
      for (const row of maxSo || []) {
        const m = (row.sale_number as string).match(/^SO-(\d+)$/);
        if (m) {
          const num = parseInt(m[1], 10);
          if (num > maxNum) maxNum = num;
        }
      }
      const nextSoNum = `SO-${String(maxNum + 1).padStart(5, "0")}`;

      let defaultWarehouseId: string | null = null;
      let defaultWarehouseName: string | null = null;

      const defaultWhData = await client.unsafe(
        `SELECT id, name FROM warehouses WHERE entity_id = $1 AND is_default_for_branch = true LIMIT 1`,
        [starlexOrgEntityId],
      );

      if (defaultWhData[0]) {
        defaultWarehouseId = defaultWhData[0].id;
        defaultWarehouseName = defaultWhData[0].name;
      } else {
        const fallbackWhData = await client.unsafe(
          `SELECT id, name FROM warehouses WHERE entity_id = $1 LIMIT 1`,
          [starlexOrgEntityId],
        );
        if (fallbackWhData[0]) {
          defaultWarehouseId = fallbackWhData[0].id;
          defaultWarehouseName = fallbackWhData[0].name;
        }
      }

      const subtotal = po.subtotal ? parseFloat(po.subtotal.toString()) : 0.0;
      const taxAmount = po.tax_amount ? parseFloat(po.tax_amount.toString()) : 0.0;
      const total = po.total ? parseFloat(po.total.toString()) : 0.0;
      const discount = po.discount ? parseFloat(po.discount.toString()) : 0.0;
      const adjustment = po.adjustment ? parseFloat(po.adjustment.toString()) : 0.0;

      const soRows = await client.unsafe(
        `INSERT INTO sales_orders (
          entity_id, customer_id, sale_number, reference, sale_date, status, document_type,
          sub_total, tax_total, discount_total, adjustment, total_quantity, total,
          warehouse_id, warehouse_name, is_delete
        ) VALUES ($1, $2, $3, $4, $5, 'confirmed', 'order', $6, $7, $8, $9, $10, $11, $12, $13, false)
        RETURNING *`,
        [
          starlexOrgEntityId,
          customerId,
          nextSoNum,
          po.order_number,
          new Date().toISOString(),
          subtotal,
          taxAmount,
          discount,
          adjustment,
          po.items ? po.items.reduce((sum: number, item: any) => sum + (parseFloat(item.quantity?.toString() || "0")), 0) : 0,
          total,
          defaultWarehouseId,
          defaultWarehouseName,
        ],
      );

      const so = soRows[0];
      if (!so) {
        throw new BadRequestException("Failed to insert Sales Order");
      }

      const soItems = (po.items || []).map((item: any, index: number) => {
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
        try {
          for (const item of soItems) {
            await client.unsafe(
              `INSERT INTO sales_order_items (
                sales_order_id, line_no, product_id, description, quantity, rate,
                discount_type, discount_value, discount_amount, tax_id, tax_rate, tax_amount,
                amount, hsn_code, accounts, entity_id, is_invoiced
              ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)`,
              [
                item.sales_order_id,
                item.line_no,
                item.product_id,
                item.description,
                item.quantity,
                item.rate,
                item.discount_type,
                item.discount_value,
                item.discount_amount,
                item.tax_id,
                item.tax_rate,
                item.tax_amount,
                item.amount,
                item.hsn_code,
                item.accounts,
                item.entity_id,
                item.is_invoiced,
              ],
            );
          }
        } catch (itemsError) {
          await client.unsafe(`DELETE FROM sales_orders WHERE id = $1`, [so.id]);
          throw itemsError;
        }
      }

      const maxPl = await client.unsafe(
        `SELECT picklist_no FROM picklist_master WHERE entity_id = $1 AND picklist_no LIKE 'PL-%'`,
        [starlexOrgEntityId],
      );

      let maxPlNum = 0;
      for (const row of maxPl || []) {
        const m = (row.picklist_no as string).match(/^PL-(\d+)$/);
        if (m) {
          const num = parseInt(m[1], 10);
          if (num > maxPlNum) maxPlNum = num;
        }
      }
      const nextPlNum = `PL-${String(maxPlNum + 1).padStart(5, "0")}`;

      const plRows = await client.unsafe(
        `INSERT INTO picklist_master (
          picklist_no, entity_id, warehouse_id, picklist_date, status, is_delete, is_entrypass
        ) VALUES ($1, $2, $3, $4, 'DRAFT', false, false)
        RETURNING *`,
        [
          nextPlNum,
          starlexOrgEntityId,
          defaultWarehouseId,
          new Date().toISOString().split("T")[0],
        ],
      );

      const picklist = plRows[0];
      if (!picklist) {
        throw new BadRequestException("Failed to insert Picklist");
      }

      const createdSoItems = await client.unsafe(
        `SELECT id, product_id, quantity FROM sales_order_items WHERE sales_order_id = $1`,
        [so.id],
      );

      if (createdSoItems && createdSoItems.length > 0) {
        for (const soItem of createdSoItems) {
          const qty = parseFloat(soItem.quantity?.toString() || "0");
          await client.unsafe(
            `INSERT INTO picklist_items (
              picklist_id, product_id, sales_order_id, sales_order_line_id,
              qty_ordered, qty_to_pick, qty_picked, status
            ) VALUES ($1, $2, $3, $4, $5, $6, 0.0, 'YET_TO_START')`,
            [
              picklist.id,
              soItem.product_id,
              so.id,
              soItem.id,
              qty,
              qty,
            ],
          );
        }
      }

      results.push({ poId, status: "approved", salesOrderId: so.id, picklistId: picklist.id });
    }

    return results;
  }

  async updateSalesOrderStatus(id: string, entityId: string, status: string, reason: string) {
    const rows = await client.unsafe(
      `SELECT status FROM sales_orders WHERE id = $1 AND entity_id = $2 LIMIT 1`,
      [id, entityId],
    );

    if (!rows[0]) {
      throw new NotFoundException(`Sales order not found`);
    }

    let sqlQuery = `UPDATE sales_orders SET status = $1, updated_at = NOW()`;
    const params: any[] = [status];

    if (status.toLowerCase() === "void") {
      params.push(reason);
      sqlQuery += `, reason_to_void = $2`;
    } else if (status.toLowerCase() === "confirmed") {
      params.push(reason);
      sqlQuery += `, reason_to_confirmed = $2`;
    }

    params.push(id, entityId);
    sqlQuery += ` WHERE id = $${params.length - 1} AND entity_id = $${params.length} RETURNING *`;

    const updatedRows = await client.unsafe(sqlQuery, params);
    const updatedOrder = updatedRows[0];

    if (!updatedOrder) {
      throw new BadRequestException("Failed to update sales order status");
    }

    return updatedOrder;
  }

  private async postInvoiceTransactions(tenant: TenantContext, invoice: any, dto: any) {
    if (!invoice || !invoice.id) return;

    const invoiceId = invoice.id;
    const orgId = invoice.entity_id || tenant?.entityId;
    const status = (invoice.status || dto.status || "draft").toString().toLowerCase();

    if (status === "draft") {
      const existingJE = await client.unsafe(
        `SELECT id FROM journal_entries WHERE entity_id = $1 AND source_document_type = 'INVOICE' AND source_document_id = $2 LIMIT 1`,
        [orgId, invoiceId],
      );

      if (existingJE[0]?.id) {
        await client.unsafe(`DELETE FROM journal_entry_lines WHERE journal_entry_id = $1`, [existingJE[0].id]);
        await client.unsafe(`DELETE FROM journal_entries WHERE id = $1`, [existingJE[0].id]);
      }
      return;
    }

    const dbAccounts = await client.unsafe(
      `SELECT id, system_account_name, user_account_name, account_type, account_group FROM accounts`,
    );

    if (!dbAccounts || dbAccounts.length === 0) {
      console.warn("No active accounts found in database for posting invoice transactions");
      return;
    }

    const findAccount = (names: string[], types?: string[]): string | null => {
      const match = dbAccounts.find((acc: any) => {
        const uName = acc.user_account_name?.toLowerCase() || "";
        const sName = acc.system_account_name?.toLowerCase() || "";
        const aName = acc.account_name?.toLowerCase() || "";
        const aType = acc.account_type?.toLowerCase() || "";

        const nameMatch = names.some((n) => {
          const ln = n.toLowerCase();
          return uName.includes(ln) || sName.includes(ln) || aName.includes(ln);
        });

        const typeMatch = types ? types.some((t) => aType === t.toLowerCase()) : true;
        return nameMatch && typeMatch;
      });

      if (match) return match.id;

      if (types && types.length > 0) {
        const typeMatch = dbAccounts.find((acc: any) =>
          types.some((t) => acc.account_type?.toLowerCase() === t.toLowerCase()),
        );
        if (typeMatch) return typeMatch.id;
      }

      return dbAccounts[0]?.id || null;
    };

    const accountsReceivableId = findAccount(["Accounts Receivable"], ["Accounts Receivable"]);
    const accountsReceivableDiscountId = findAccount(["Accounts Receivable (discount)", "Accounts Receivable discount"], ["Accounts Receivable"]) || accountsReceivableId;
    const salesDiscountId = findAccount(["Sales Discounts", "Sales Discount", "Discount"], ["Income", "Other Income", "Expense", "Other Expense"]);
    const salesAccountId = findAccount(["Sales", "Sales Account", "General Income"], ["Income", "Other Income"]);
    const otherExpensesId = findAccount(["Other Expenses", "Other Expense", "Adjustment", "Other Income"], ["Expense", "Other Expense", "Income", "Other Income"]);
    const outputSgstId = findAccount(["Output SGST", "SGST"], ["Other Current Liability", "Other Liability", "Other Current Asset", "Other Asset"]);
    const outputCgstId = findAccount(["Output CGST", "CGST"], ["Other Current Liability", "Other Liability", "Other Current Asset", "Other Asset"]);
    const outputIgstId = findAccount(["Output IGST", "IGST"], ["Other Current Liability", "Other Liability", "Other Current Asset", "Other Asset"]);
    const tcsPayableId = findAccount(["TCS Payable", "TCS"], ["Other Current Liability", "Other Liability"]);
    const tdsReceivableId = findAccount(["TDS Receivable", "TDS"], ["Other Current Asset", "Other Asset"]);
    const cogsId = findAccount(["Cost of Goods Sold", "COGS"], ["Cost Of Goods Sold", "Expense", "Other Expense"]);
    const inventoryAssetId = findAccount(["Inventory Asset", "Stock", "Finished Goods"], ["Stock", "Assets", "Other Current Asset"]);

    const discountAmount = parseFloat(invoice.discount_total?.toString() || dto.discountTotal?.toString() || dto.discountAmount?.toString() || "0");
    const taxAmount = parseFloat(invoice.tax_total?.toString() || dto.taxTotal?.toString() || dto.taxAmount?.toString() || "0");
    const tdsAmount = parseFloat(invoice.tds_total?.toString() || dto.tdsTotal?.toString() || "0");
    const tcsAmount = parseFloat(invoice.tcs_total?.toString() || dto.tcsTotal?.toString() || "0");
    const adjustmentAmount = parseFloat(invoice.adjustment_amount?.toString() || dto.adjustmentAmount?.toString() || dto.adjustment?.toString() || "0");
    const subtotalAmount = parseFloat(invoice.subtotal?.toString() || dto.subtotal?.toString() || "0");
    const grandTotalAmount = parseFloat(invoice.grand_total?.toString() || dto.grandTotal?.toString() || "0");
    const invoiceDate = invoice.invoice_date || dto.invoiceDate || new Date().toISOString().split("T")[0];
    const invoiceNumber = invoice.invoice_number || dto.invoiceNumber || `INV-${Date.now()}`;
    const customerId = invoice.customer_id || dto.customerId || null;

    const isGstInvoice = taxAmount > 0.0001;
    let isIGST = false;

    if (isGstInvoice && dto.items?.length > 0) {
      const taxIds = dto.items.map((item: any) => item.tax_id || item.taxId).filter(Boolean);
      if (taxIds.length > 0) {
        const rates = await client.unsafe(
          `SELECT tax_type FROM tax_rates WHERE id = ANY($1)`,
          [taxIds],
        );
        if (rates && rates.some((r: any) => r.tax_type === "IGST")) {
          isIGST = true;
        }
      }
    }

    let totalCostOfGoods = 0;
    if (dto.items && Array.isArray(dto.items)) {
      for (const item of dto.items) {
        if (item.batches && Array.isArray(item.batches)) {
          for (const b of item.batches) {
            const bQty = parseFloat(b.quantity?.toString() || "0");
            const bRate = parseFloat(b.purchaseRate?.toString() || b.purchase_rate?.toString() || b.salesRate?.toString() || "0");
            totalCostOfGoods += (bQty * bRate);
          }
        }
      }
    }

    let currentUserId: string | null = null;
    const userIdVal = tenant?.userId || dto?.user_id || dto?.userId;
    if (userIdVal && this.isUuid(String(userIdVal))) {
      currentUserId = String(userIdVal);
    } else {
      const firstUser = await client.unsafe(`SELECT id FROM users LIMIT 1`);
      if (firstUser[0]) currentUserId = firstUser[0].id;
    }

    const existingJE = await client.unsafe(
      `SELECT id, created_by FROM journal_entries WHERE entity_id = $1 AND source_document_type = 'INVOICE' AND source_document_id = $2 LIMIT 1`,
      [orgId, invoiceId],
    );

    const journalEntryId = existingJE[0]?.id || uuidv4();
    const defaultOrgId = "00000000-0000-0000-0000-000000000000";

    if (existingJE[0]?.id) {
      await client.unsafe(`DELETE FROM journal_entry_lines WHERE journal_entry_id = $1`, [existingJE[0].id]);
      await client.unsafe(
        `UPDATE journal_entries SET
           org_id = $1, entity_id = $2, journal_number = $3, journal_type = 'INVOICE',
           journal_date = $4, posting_date = $4, reference_number = $5, narration = $6,
           source_module = 'SALES', source_document_type = 'INVOICE', source_document_id = $7,
           currency_code = 'INR', exchange_rate = 1.0, status = 'POSTED', updated_by = $8
         WHERE id = $9`,
        [
          tenant?.orgId || defaultOrgId,
          orgId,
          `JE-${invoiceNumber}`,
          invoiceDate,
          invoiceNumber,
          invoice.customer_notes || dto.customerNotes || `Sales Invoice ${invoiceNumber}`,
          invoiceId,
          currentUserId,
          journalEntryId,
        ],
      );
    } else {
      await client.unsafe(
        `INSERT INTO journal_entries (
          id, org_id, entity_id, journal_number, journal_type, journal_date, posting_date,
          reference_number, narration, source_module, source_document_type, source_document_id,
          currency_code, exchange_rate, status, created_by, updated_by
        ) VALUES ($1, $2, $3, $4, 'INVOICE', $5, $5, $6, $7, 'SALES', 'INVOICE', $8, 'INR', 1.0, 'POSTED', $9, $9)`,
        [
          journalEntryId,
          tenant?.orgId || defaultOrgId,
          orgId,
          `JE-${invoiceNumber}`,
          invoiceDate,
          invoiceNumber,
          invoice.customer_notes || dto.customerNotes || `Sales Invoice ${invoiceNumber}`,
          invoiceId,
          currentUserId,
        ],
      );
    }

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
        });
      }
    };

    if (!isGstInvoice) {
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
      for (const entry of entries) {
        await client.unsafe(
          `INSERT INTO journal_entry_lines (
            id, journal_entry_id, entity_id, org_id, account_id, transaction_date,
            reference_number, description, debit, credit, source_id, source_type, contact_id, contact_type
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`,
          [
            entry.id,
            entry.journal_entry_id,
            entry.entity_id,
            entry.org_id,
            entry.account_id,
            entry.transaction_date,
            entry.reference_number,
            entry.description,
            entry.debit,
            entry.credit,
            entry.source_id,
            entry.source_type,
            entry.contact_id,
            entry.contact_type,
          ],
        );
      }
    }

    try {
      await client.unsafe(
        `UPDATE invoice_master SET journal_id = $1 WHERE id = $2`,
        [journalEntryId, invoiceId],
      );
    } catch (jeBacklinkErr) {
      console.error("Error updating invoice_master journal_id:", jeBacklinkErr);
    }
  }
}
