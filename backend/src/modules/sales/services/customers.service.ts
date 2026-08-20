import { BadRequestException, Injectable } from "@nestjs/common";
import { randomUUID } from "crypto";
import { SupabaseService } from "../../supabase/supabase.service";
import { R2StorageService } from "../../accountant/r2-storage.service";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SequencesService } from "../../../sequences/sequences.service";
import { db, client } from "../../../db/db";
import {
  CustomerDetailActivityDto,
  CustomerDetailCommentDto,
  CustomerDetailContextDto,
  CustomerDetailMailDto,
  CustomerDetailTransactionGroupDto,
  CustomerStatementEntryDto,
} from "../dto/customer-detail-context.dto";

@Injectable()
export class CustomersService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly r2StorageService: R2StorageService,
    private readonly sequencesService: SequencesService,
  ) {}

  private normalizeGstTreatment(val: string | null | undefined): string | null {
    if (!val) return null;
    const clean = val.trim().toLowerCase().replace(/\s+/g, "_");
    if (
      clean === "registered_business" ||
      clean === "registered_business_regular" ||
      clean.includes("regular")
    ) {
      return "registered_business_regular";
    }
    if (
      clean === "registered_business_composition" ||
      clean.includes("composition")
    ) {
      return "registered_business_composition";
    }
    if (
      clean.includes("unregistered_business") ||
      clean === "unregistered_business"
    ) {
      return "unregistered_business";
    }
    if (
      clean === "overseas" ||
      clean === "special_economic_zone" ||
      clean === "deemed_export" ||
      clean === "deemed_exports" ||
      clean === "de_emed_exports"
    ) {
      return clean === "deemed_exports" || clean === "de_emed_exports"
        ? "deemed_export"
        : clean;
    }
    if (clean === "consumer") {
      return "consumer";
    }
    return val;
  }

  async findAll(
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    _search?: string,
  ) {
    const offset = (page - 1) * limit;

    try {
      const [data, countRes] = await Promise.all([
        client.unsafe(
          `SELECT * FROM customers WHERE entity_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
          [tenant.entityId, limit, offset],
        ),
        client.unsafe(
          `SELECT COUNT(*)::int as count FROM customers WHERE entity_id = $1`,
          [tenant.entityId],
        ),
      ]);

      const totalCount = countRes[0]?.count ?? 0;
      const mapped = data ? await Promise.all(data.map((c: any) => this.mapCustomer(c))) : [];

      return {
        data: mapped,
        total: totalCount,
      };
    } catch (error) {
      throw new Error(`Failed to fetch customers: ${(error as Error).message}`);
    }
  }

  async findOne(id: string, tenant: TenantContext) {
    try {
      const rows = await client.unsafe(
        `SELECT * FROM customers WHERE id = $1 AND entity_id = $2 LIMIT 1`,
        [id, tenant.entityId],
      );

      const data = rows[0];
      if (!data) return null;

      return this.mapCustomer(data);
    } catch {
      return null;
    }
  }

  async getDetailContext(
    id: string,
    tenant: TenantContext,
  ): Promise<CustomerDetailContextDto | null> {
    const customer = await this.findOne(id, tenant);
    if (!customer) {
      return null;
    }

    const [
      salesOrders,
      salesPayments,
      invoices,
      paymentsReceived,
      allocations,
      linkedOrders,
      auditLogsRes,
    ] = await Promise.all([
      client.unsafe(
        `SELECT id, sale_number, reference, sale_date, created_at, status, total, document_type, place_of_supply
         FROM sales_orders WHERE customer_id = $1 AND entity_id = $2 ORDER BY sale_date DESC`,
        [id, tenant.entityId],
      ),
      client.unsafe(
        `SELECT id, payment_number, payment_date, payment_mode, reference, amount, notes, created_at
         FROM sales_payments WHERE customer_id = $1 AND entity_id = $2 ORDER BY payment_date DESC`,
        [id, tenant.entityId],
      ),
      client.unsafe(
        `SELECT id, invoice_number, invoice_date, due_date, grand_total, status, place_of_supply, is_delete, created_at
         FROM invoice_master WHERE customer_id = $1 AND entity_id = $2 AND is_delete = false ORDER BY invoice_date DESC`,
        [id, tenant.entityId],
      ),
      client.unsafe(
        `SELECT id, payment_number, payment_date, payment_mode, reference_number, amount_received, amount_used_for_payments, excess_amount, status, place_of_supply, is_delete, created_at
         FROM payments_received WHERE customer_id = $1 AND entity_id = $2 AND is_delete = false ORDER BY payment_date DESC`,
        [id, tenant.entityId],
      ),
      client.unsafe(
        `SELECT invoice_id, allocated_amount FROM payment_received_allocations`,
      ),
      client.unsafe(
        `SELECT invoice_id, sales_order_id FROM invoice_sales_orders`,
      ),
      client.unsafe(
        `SELECT id, table_name, record_id, action, actor_name, created_at, changed_columns, new_values, old_values
         FROM audit_logs WHERE entity_id = $1 AND table_name = ANY($2) ORDER BY created_at DESC LIMIT 200`,
        [
          tenant.entityId,
          [
            "customers",
            "sales_orders",
            "sales_payments",
            "invoice_master",
            "payments_received",
          ],
        ],
      ),
    ]);

    const auditLogs = (auditLogsRes ?? []).filter((log: any) => {
      if (log.record_id === id && log.table_name === "customers") {
        return true;
      }
      const newCustomerId = log.new_values?.customer_id?.toString?.();
      const oldCustomerId = log.old_values?.customer_id?.toString?.();
      return newCustomerId === id || oldCustomerId === id;
    });

    return {
      transactions: this.buildTransactionGroups(
        salesOrders ?? [],
        salesPayments ?? [],
        invoices ?? [],
        paymentsReceived ?? [],
        allocations ?? [],
        linkedOrders ?? [],
      ),
      activities: this.buildActivities(auditLogs),
      comments: this.buildComments(),
      mails: this.buildMails(),
      statementEntries: this.buildStatementEntries(
        customer,
        salesOrders ?? [],
        salesPayments ?? [],
      ),
    };
  }

  async create(createCustomerDto: any, tenant: TenantContext) {
    const resolvedCurrencyId = await this.resolveCurrencyId(
      createCustomerDto.currencyId ?? createCustomerDto.currencyCode,
    );
    const resolvedCustomerNumber = await this.resolveCustomerNumber(
      createCustomerDto.customerNumber,
      tenant,
    );
    const customerData = this.buildCustomerWriteModel(
      createCustomerDto,
      tenant,
      {
        resolvedCurrencyId,
        resolvedCustomerNumber,
        includeCreateDefaults: true,
      },
    );

    const keys = Object.keys(customerData);
    const values = Object.values(customerData);
    const cols = keys.map((k) => `"${k}"`).join(", ");
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");

    let customer: any;
    try {
      const rows = await client.unsafe(
        `INSERT INTO customers (${cols}) VALUES (${placeholders}) RETURNING *`,
        values,
      );
      customer = rows[0];
    } catch (customerError: any) {
      if (customerError.message?.includes("customers_customer_number_key")) {
        throw new Error("Customer number already exists");
      }
      throw new Error(`Failed to create customer: ${customerError.message}`);
    }

    if (createCustomerDto.billingAddress) {
      await this.saveAddress(customer.id, tenant, "billing", createCustomerDto.billingAddress);
    }
    if (createCustomerDto.shippingAddress) {
      await this.saveAddress(customer.id, tenant, "shipping", createCustomerDto.shippingAddress);
    }

    await this.sequencesService.incrementSequence(
      "customer",
      tenant,
      resolvedCustomerNumber,
    );

    if (
      createCustomerDto.contactPersons &&
      createCustomerDto.contactPersons.length > 0
    ) {
      for (let index = 0; index < createCustomerDto.contactPersons.length; index++) {
        const contact = createCustomerDto.contactPersons[index];
        await client.unsafe(
          `INSERT INTO customer_contact_persons (customer_id, salutation, first_name, last_name, email, work_phone, mobile_phone, display_order)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [
            customer.id,
            contact.salutation ?? null,
            contact.firstName ?? null,
            contact.lastName ?? null,
            contact.email ?? null,
            contact.workPhone ?? null,
            contact.mobilePhone ?? null,
            index,
          ],
        );
      }
    }

    try {
      const customerName =
        customer.display_name ||
        customer.company_name ||
        `${customer.first_name || ""} ${customer.last_name || ""}`.trim() ||
        customer.customer_number;
      const customerRemarks = (customer.remarks || createCustomerDto.remarks || "")
        .toString()
        .trim() || null;
      const customerCurrency =
        createCustomerDto.currency ||
        createCustomerDto.currencyCode ||
        customer.currency ||
        "INR";

      const existingAccountRows = await client.unsafe(
        `SELECT id FROM accounts
         WHERE entity_id = $1 AND account_type = 'Accounts Receivable'
         AND (system_account_name = $2 OR user_account_name = $2) LIMIT 1`,
        [tenant.entityId, customerName],
      );

      const existingAccount = existingAccountRows[0];
      let accountId = existingAccount?.id;

      if (!existingAccount) {
        const newAccRows = await client.unsafe(
          `INSERT INTO accounts (system_account_name, user_account_name, account_type, account_group, account_code, description, currency, is_active, is_system, is_deletable, show_in_zerpai_expense, is_deleted, entity_id, org_id)
           VALUES ($1, $1, 'Accounts Receivable', 'Assets', $2, $3, $4, true, false, true, false, false, $5, $6)
           RETURNING id`,
          [
            customerName,
            customer.customer_number || null,
            customerRemarks,
            customerCurrency,
            tenant.entityId,
            tenant.orgId || "00000000-0000-0000-0000-000000000000",
          ],
        );
        accountId = newAccRows[0]?.id;
      } else {
        await client.unsafe(
          `UPDATE accounts SET description = $1, currency = $2 WHERE id = $3`,
          [customerRemarks, customerCurrency, existingAccount.id],
        );
      }

      if (accountId) {
        await client.unsafe(
          `UPDATE customers SET account_id = $1 WHERE id = $2`,
          [accountId, customer.id],
        );
        customer.account_id = accountId;
      }
    } catch (accErr) {
      console.error("⚠️ Failed to sync customer account in accounts table:", accErr);
    }

    return this.mapCustomer(customer);
  }

  async update(id: string, tenant: TenantContext, updateCustomerDto: any) {
    const resolvedCurrencyId =
      "currencyId" in updateCustomerDto || "currencyCode" in updateCustomerDto
        ? await this.resolveCurrencyId(
            updateCustomerDto.currencyId ?? updateCustomerDto.currencyCode,
          )
        : undefined;
    const resolvedCustomerNumber =
      "customerNumber" in updateCustomerDto
        ? updateCustomerDto.customerNumber?.toString().trim() || undefined
        : undefined;

    const payload = this.buildCustomerWriteModel(updateCustomerDto, tenant, {
      resolvedCurrencyId,
      resolvedCustomerNumber,
      includeCreateDefaults: false,
    });

    const cleanedPayload = Object.fromEntries(
      Object.entries(payload).filter(([_, v]) => v !== undefined),
    );

    let customerData: any = null;
    if (Object.keys(cleanedPayload).length > 0) {
      const keys = Object.keys(cleanedPayload);
      const setClauses = keys.map((k, i) => `"${k}" = $${i + 1}`).join(", ");
      const values = Object.values(cleanedPayload);

      try {
        const rows = await client.unsafe(
          `UPDATE customers SET ${setClauses} WHERE id = $${keys.length + 1} AND entity_id = $${keys.length + 2} RETURNING *`,
          [...values, id, tenant.entityId],
        );
        customerData = rows[0];
        if (!customerData) return null;
      } catch (error: any) {
        if (error.message?.includes("customers_customer_number_key")) {
          throw new Error("Customer number already exists");
        }
        throw new Error(`Failed to update customer: ${error.message}`);
      }
    } else {
      const rows = await client.unsafe(
        `SELECT * FROM customers WHERE id = $1 AND entity_id = $2 LIMIT 1`,
        [id, tenant.entityId],
      );
      customerData = rows[0];
      if (!customerData) return null;
    }

    if (updateCustomerDto.billingAddress) {
      await this.saveAddress(id, tenant, "billing", updateCustomerDto.billingAddress);
    }
    if (updateCustomerDto.shippingAddress) {
      await this.saveAddress(id, tenant, "shipping", updateCustomerDto.shippingAddress);
    }

    return this.mapCustomer(customerData);
  }

  async bulkUpdate(
    tenant: TenantContext,
    customerIds: string[],
    updateCustomerDto: any,
  ) {
    const updated: any[] = [];
    const failed: Array<{ id: string; reason: string }> = [];
    const requestId = `customers-bulk-update-${Date.now()}-${randomUUID()}`;
    const changedColumns = Object.keys(updateCustomerDto ?? {});

    for (const id of customerIds) {
      try {
        const row = await this.update(id, tenant, updateCustomerDto);
        if (!row) {
          failed.push({ id, reason: "Customer not found" });
          continue;
        }
        updated.push(row);
      } catch (error) {
        failed.push({
          id,
          reason: error instanceof Error ? error.message : "Unknown error",
        });
      }
    }

    await this.writeBulkUpdateAuditLogs(
      tenant,
      requestId,
      customerIds,
      updateCustomerDto,
      changedColumns,
      updated,
      failed,
    );

    return {
      requestedCount: customerIds.length,
      updatedCount: updated.length,
      failedCount: failed.length,
      updated,
      failed,
      requestId,
    };
  }

  private async writeBulkUpdateAuditLogs(
    tenant: TenantContext,
    requestId: string,
    customerIds: string[],
    updateData: Record<string, unknown>,
    changedColumns: string[],
    updated: any[],
    failed: Array<{ id: string; reason: string }>,
  ): Promise<void> {
    const actorName = tenant.userId || "system";
    const entityId = tenant.entityId?.trim();
    const orgId = tenant.orgId?.trim();
    if (!entityId || !orgId) {
      throw new BadRequestException(
        "Missing tenant scope for customer bulk-update audit logs.",
      );
    }

    const summaryRecordId = customerIds[0];
    if (!summaryRecordId) {
      throw new BadRequestException(
        "No customer IDs provided for customer bulk-update audit logs.",
      );
    }

    const summaryEntry = {
      table_name: "customers",
      record_id: summaryRecordId,
      action: "BULK_UPDATE_REQUEST",
      old_values: null,
      new_values: JSON.stringify({
        requestId,
        requestedCount: customerIds.length,
        changedColumns,
        updateData,
        updatedCount: updated.length,
        failedCount: failed.length,
      }),
      user_id: tenant.userId,
      org_id: orgId,
      entity_id: entityId,
      actor_name: actorName,
      schema_name: "public",
      record_pk: summaryRecordId,
      changed_columns: changedColumns,
      source: "api",
      module_name: "sales.customers.bulk_update",
      request_id: requestId,
    };

    const itemEntries = [
      ...updated.map((row: any) => ({
        table_name: "customers",
        record_id: row.id,
        action: "BULK_UPDATE_ITEM_SUCCESS",
        old_values: null,
        new_values: JSON.stringify({
          requestId,
          status: "success",
          changedColumns,
          updateData,
        }),
        user_id: tenant.userId,
        org_id: orgId,
        entity_id: entityId,
        actor_name: actorName,
        schema_name: "public",
        record_pk: row.id,
        changed_columns: changedColumns,
        source: "api",
        module_name: "sales.customers.bulk_update",
        request_id: requestId,
      })),
      ...failed.map((entry) => ({
        table_name: "customers",
        record_id: entry.id,
        action: "BULK_UPDATE_ITEM_FAILED",
        old_values: null,
        new_values: JSON.stringify({
          requestId,
          status: "failed",
          reason: entry.reason,
          changedColumns,
          updateData,
        }),
        user_id: tenant.userId,
        org_id: orgId,
        entity_id: entityId,
        actor_name: actorName,
        schema_name: "public",
        record_pk: entry.id,
        changed_columns: changedColumns,
        source: "api",
        module_name: "sales.customers.bulk_update",
        request_id: requestId,
      })),
    ];

    for (const log of [summaryEntry, ...itemEntries]) {
      await client.unsafe(
        `INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values, user_id, org_id, entity_id, actor_name, schema_name, record_pk, changed_columns, source, module_name, request_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)`,
        [
          log.table_name,
          log.record_id,
          log.action,
          log.old_values,
          log.new_values,
          log.user_id,
          log.org_id,
          log.entity_id,
          log.actor_name,
          log.schema_name,
          log.record_pk,
          log.changed_columns,
          log.source,
          log.module_name,
          log.request_id,
        ],
      );
    }
  }

  private buildCustomerWriteModel(
    dto: any,
    tenant: TenantContext,
    options: {
      resolvedCurrencyId?: string | null;
      resolvedCustomerNumber?: string;
      includeCreateDefaults: boolean;
    },
  ) {
    const customerData: Record<string, any> = {
      customer_type: dto.customerType,
      customer_number: options.resolvedCustomerNumber,
      salutation: dto.salutation,
      first_name: dto.firstName,
      last_name: dto.lastName,
      company_name: dto.companyName,
      display_name: dto.displayName,

      email: dto.email,
      phone: dto.phone,
      mobile_phone: dto.mobilePhone,
      website: dto.website,
      designation: dto.designation,
      department: dto.department,
      business_type: dto.businessType,
      customer_language: dto.customerLanguage,

      date_of_birth: dto.dateOfBirth,
      age: dto.age,
      gender: dto.gender,
      place_of_customer: dto.placeOfCustomer,
      privilege_card_number: dto.privilegeCardNumber,
      parent_customer_id: dto.parentCustomerId,

      gst_treatment: this.normalizeGstTreatment(dto.gstTreatment),
      gstin: dto.gstin,
      pan: dto.pan,
      place_of_supply: dto.placeOfSupply,
      tax_preference: dto.taxPreference,
      exemption_reason: dto.exemptionReason,

      is_drug_registered: dto.isDrugRegistered,
      is_fssai_registered: dto.isFssaiRegistered,
      is_msme_registered: dto.isMsmeRegistered,
      drug_licence_type: dto.drugLicenceType,
      drug_license_20: dto.drugLicense20,
      drug_license_21: dto.drugLicense21,
      drug_license_20b: dto.drugLicense20B,
      drug_license_21b: dto.drugLicense21B,
      fssai: dto.fssai,
      msme_registration_type: dto.msmeRegistrationType,
      msme_number: dto.msmeNumber,

      drug_license_20_doc_url: dto.drugLicense20DocUrl,
      drug_license_21_doc_url: dto.drugLicense21DocUrl,
      drug_license_20b_doc_url: dto.drugLicense20BDocUrl,
      drug_license_21b_doc_url: dto.drugLicense21BDocUrl,
      fssai_doc_url: dto.fssaiDocUrl,
      msme_doc_url: dto.msmeDocUrl,
      document_urls: dto.documentUrls,

      currency_id: options.resolvedCurrencyId,
      opening_balance: dto.openingBalance,
      credit_limit: dto.creditLimit,
      payment_terms: dto.paymentTerms,
      price_list_id: dto.priceListId,
      receivable_balance: dto.receivableBalance,

      enable_portal: dto.enablePortal,
      facebook_handle: dto.facebookHandle,
      twitter_handle: dto.twitterHandle,
      whatsapp_number: dto.whatsappNumber,
      is_recurring: dto.isRecurring,

      remarks: dto.remarks,
    };

    if (options.includeCreateDefaults) {
      customerData["entity_id"] = tenant.entityId;
      customerData["status"] = "active";
      if (customerData["customer_language"] == null) {
        customerData["customer_language"] = "English";
      }
      if (customerData["opening_balance"] == null) {
        customerData["opening_balance"] = 0;
      }
      if (customerData["receivable_balance"] == null) {
        customerData["receivable_balance"] = 0;
      }
      if (customerData["enable_portal"] == null) {
        customerData["enable_portal"] = false;
      }
      if (customerData["is_recurring"] == null) {
        customerData["is_recurring"] = false;
      }
    }

    return Object.fromEntries(
      Object.entries(customerData).filter(([, value]) => value !== undefined),
    );
  }

  async remove(id: string, tenant: TenantContext) {
    const customer = await this.findOne(id, tenant);
    if (!customer) return false;

    try {
      await client.unsafe(
        `DELETE FROM customers WHERE id = $1 AND entity_id = $2`,
        [id, tenant.entityId],
      );

      const docFields = [
        "drug_license_20_doc_url",
        "drug_license_21_doc_url",
        "drug_license_20b_doc_url",
        "drug_license_21b_doc_url",
        "fssai_doc_url",
        "msme_doc_url",
        "document_urls",
      ];

      for (const field of docFields) {
        const key = customer[field];
        if (key && typeof key === "string" && !key.startsWith("http")) {
          try {
            await this.r2StorageService.deleteFile(key);
          } catch (e) {
            console.error(
              `Failed to cleanup R2 file ${key} for deleted customer ${id}`,
              e,
            );
          }
        }
      }
      return true;
    } catch {
      return false;
    }
  }

  async getStatistics(tenant: TenantContext) {
    const [totalRes, activeRes] = await Promise.all([
      client.unsafe(
        `SELECT COUNT(*)::int as count FROM customers WHERE entity_id = $1`,
        [tenant.entityId],
      ),
      client.unsafe(
        `SELECT COUNT(*)::int as count FROM customers WHERE entity_id = $1 AND status = 'active'`,
        [tenant.entityId],
      ),
    ]);

    const total = totalRes[0]?.count ?? 0;
    const active = activeRes[0]?.count ?? 0;

    return {
      total,
      active,
      inactive: total - active,
    };
  }

  private async mapCustomer(customer: any) {
    if (!customer) return null;

    const docFields = [
      "drug_license_20_doc_url",
      "drug_license_21_doc_url",
      "drug_license_20b_doc_url",
      "drug_license_21b_doc_url",
      "fssai_doc_url",
      "msme_doc_url",
      "document_urls",
    ];

    for (const field of docFields) {
      const key = customer[field];
      if (key && typeof key === "string" && !key.startsWith("http")) {
        try {
          customer[field] = await this.r2StorageService.getPresignedUrl(key);
        } catch (e) {
          console.error(
            `Failed to sign ${field} for customer ${customer.id}`,
            e,
          );
        }
      }
    }

    try {
      const addresses = await client.unsafe(
        `SELECT * FROM customer_addresses WHERE customer_id = $1 AND is_active = true`,
        [customer.id],
      );

      if (addresses) {
        const billing = addresses.find((a: any) => a.is_default_billing) ||
                        addresses.find((a: any) => a.address_type === "billing");
        if (billing) {
          customer.billingAddressStreet1 = billing.address_street;
          customer.billingAddressStreet2 = billing.address_place;
          customer.billingAddressCity = billing.city;
          customer.billingAddressStateId = billing.state;
          customer.billingAddressZip = billing.pincode;
          customer.billingAddressCountryId = billing.country_region;
          customer.billingAddressPhone = billing.phone;
        }

        const shipping = addresses.find((a: any) => a.is_default_shipping) ||
                          addresses.find((a: any) => a.address_type === "shipping");
        if (shipping) {
          customer.shippingAddressStreet1 = shipping.address_street;
          customer.shippingAddressStreet2 = shipping.address_place;
          customer.shippingAddressCity = shipping.city;
          customer.shippingAddressStateId = shipping.state;
          customer.shippingAddressZip = shipping.pincode;
          customer.shippingAddressCountryId = shipping.country_region;
          customer.shippingAddressPhone = shipping.phone;
        }
      }
    } catch (e) {
      console.error(`Failed to map customer addresses for ${customer.id}:`, e);
    }

    return customer;
  }

  private async saveAddress(
    customerId: string,
    tenant: TenantContext,
    addressType: "billing" | "shipping",
    addressDto: any,
  ) {
    if (!addressDto) return;

    try {
      const existing = await client.unsafe(
        `SELECT id FROM customer_addresses WHERE customer_id = $1 AND address_type = $2 LIMIT 1`,
        [customerId, addressType],
      );

      if (existing[0]?.id) {
        await client.unsafe(
          `UPDATE customer_addresses SET
             address_street = $1, address_place = $2, city = $3, state = $4, pincode = $5, country_region = $6, phone = $7, is_active = true, updated_at = NOW()
           WHERE id = $8`,
          [
            addressDto.street1 ?? addressDto.street,
            addressDto.place,
            addressDto.city,
            addressDto.stateId,
            addressDto.zip,
            addressDto.countryId ?? "India",
            addressDto.phone,
            existing[0].id,
          ],
        );
      } else {
        await client.unsafe(
          `INSERT INTO customer_addresses (entity_id, customer_id, address_type, address_street, address_place, city, state, pincode, country_region, phone, is_active, is_default_billing, is_default_shipping)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, true, $11, $12)`,
          [
            tenant.entityId,
            customerId,
            addressType,
            addressDto.street1 ?? addressDto.street,
            addressDto.place,
            addressDto.city,
            addressDto.stateId,
            addressDto.zip,
            addressDto.countryId ?? "India",
            addressDto.phone,
            addressType === "billing",
            addressType === "shipping",
          ],
        );
      }
    } catch (e) {
      console.error(`Error in saveAddress:`, e);
    }
  }

  private isUuid(value?: string | null): boolean {
    if (!value) return false;
    return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
      value.trim(),
    );
  }

  private async resolveCurrencyId(
    rawCurrency?: string | null,
  ): Promise<string | null> {
    const trimmed = rawCurrency?.trim();
    if (!trimmed) {
      return null;
    }

    if (this.isUuid(trimmed)) {
      return trimmed;
    }

    try {
      const rows = await client.unsafe(
        `SELECT id FROM currencies WHERE UPPER(code) = $1 AND is_active = true LIMIT 1`,
        [trimmed.toUpperCase()],
      );
      return rows[0]?.id ?? null;
    } catch (error) {
      throw new Error(`Failed to resolve currency: ${(error as Error).message}`);
    }
  }

  private async resolveCustomerNumber(
    rawCustomerNumber: string | null | undefined,
    tenant: TenantContext,
  ): Promise<string> {
    const trimmed = rawCustomerNumber?.trim();
    if (trimmed) {
      return trimmed;
    }

    return this.sequencesService.getNextNumberFormatted("customer", tenant);
  }

  private buildTransactionGroups(
    salesOrders: any[],
    salesPayments: any[],
    invoices: any[] = [],
    paymentsReceived: any[] = [],
    allocations: any[] = [],
    linkedOrders: any[] = [],
  ): CustomerDetailTransactionGroupDto[] {
    const allocatedByInvoice = new Map<string, number>();
    for (const alloc of allocations) {
      if (alloc.invoice_id) {
        const current = allocatedByInvoice.get(alloc.invoice_id) ?? 0;
        allocatedByInvoice.set(
          alloc.invoice_id,
          current + Number(alloc.allocated_amount ?? 0),
        );
      }
    }

    const soNumberMap = new Map<string, string>();
    for (const so of salesOrders) {
      if (so.id && so.sale_number) {
        soNumberMap.set(so.id, so.sale_number);
      }
    }

    const invoiceOrderNumMap = new Map<string, string>();
    for (const link of linkedOrders) {
      if (link.invoice_id && link.sales_order_id) {
        const num = soNumberMap.get(link.sales_order_id);
        if (num) {
          invoiceOrderNumMap.set(link.invoice_id, num);
        }
      }
    }

    const groups = [
      { key: "invoice", label: "Invoices" },
      { key: "payment", label: "Customer Payments" },
      { key: "retainer_invoice", label: "Retainer Invoices" },
      { key: "order", label: "Sales Orders" },
      { key: "package", label: "Packages" },
      { key: "shipment", label: "Shipments" },
      { key: "challan", label: "Delivery Challans" },
      { key: "bill", label: "Bills" },
      { key: "credit_note", label: "Credit Notes" },
      { key: "recurring_invoice", label: "Recurring Invoices" },
      { key: "payment_link", label: "Payment Links" },
    ];

    return groups.map((group) => {
      if (group.key === "invoice") {
        const items = invoices.map((inv: any) => {
          const total = Number(inv.grand_total ?? 0);
          const allocated = allocatedByInvoice.get(inv.id) ?? 0;
          const due = Math.max(0, total - allocated);
          const orderNum = invoiceOrderNumMap.get(inv.id) || "-";
          const rawStatus = (inv.status ?? "Draft").toString();
          const status =
            rawStatus.charAt(0).toUpperCase() + rawStatus.slice(1).toLowerCase();

          return {
            id: inv.id?.toString() ?? "",
            number: inv.invoice_number?.toString() ?? "Invoice",
            title: "Invoice",
            status: status,
            amount: total,
            date:
              inv.invoice_date?.toString() ?? inv.created_at?.toString() ?? null,
            location: inv.place_of_supply?.toString() ?? "-",
            orderNumber: orderNum,
            referenceNumber: null,
            paymentMode: null,
            balanceDue: due,
            unusedAmount: null,
            dueDate: inv.due_date?.toString() ?? null,
            shipmentDate: null,
            trackingNumber: null,
            vendorName: null,
            lineItemsTotal: null,
          };
        });

        return {
          key: group.key,
          label: group.label,
          count: items.length,
          items,
        };
      }

      if (group.key === "payment") {
        const sourceList =
          paymentsReceived.length > 0 ? paymentsReceived : salesPayments;

        const items = sourceList.map((p: any) => {
          const isPR = "amount_received" in p;
          const amount = isPR
            ? Number(p.amount_received ?? 0)
            : Number(p.amount ?? 0);
          const used = isPR ? Number(p.amount_used_for_payments ?? 0) : 0;
          const excess = isPR ? Number(p.excess_amount ?? 0) : 0;
          const unused = excess > 0 ? excess : Math.max(0, amount - used);
          const pNumber = isPR
            ? p.payment_number?.toString() ?? "Payment"
            : p.payment_number?.toString() ?? "Payment";
          const pDate = isPR
            ? p.payment_date?.toString() ?? p.created_at?.toString() ?? null
            : p.payment_date?.toString() ?? p.created_at?.toString() ?? null;
          const pMode = isPR
            ? p.payment_mode?.toString() ?? "Cash"
            : p.payment_mode?.toString() ?? "Cash";
          const pRef = isPR
            ? p.reference_number?.toString() ?? "-"
            : p.reference?.toString() ?? "-";
          const loc = isPR ? p.place_of_supply?.toString() ?? "-" : "-";
          const rawStatus = (p.status ?? "Recorded").toString();
          const status =
            rawStatus.charAt(0).toUpperCase() + rawStatus.slice(1).toLowerCase();

          return {
            id: p.id?.toString() ?? "",
            number: pNumber,
            title: "Customer Payment",
            status: status,
            amount: amount,
            date: pDate,
            location: loc,
            orderNumber: null,
            referenceNumber: pRef,
            paymentMode: pMode,
            balanceDue: null,
            unusedAmount: unused,
            dueDate: null,
            shipmentDate: null,
            trackingNumber: null,
            vendorName: null,
            lineItemsTotal: null,
          };
        });

        return {
          key: group.key,
          label: group.label,
          count: items.length,
          items,
        };
      }

      if (group.key === "payment_link") {
        return {
          key: group.key,
          label: group.label,
          count: 0,
          items: [],
        };
      }

      const items = salesOrders
        .filter((order: any) => order.document_type === group.key)
        .map((order: any) => {
          const total = Number(order.total ?? 0);
          const rawStatus = (order.status ?? "Draft").toString();
          const status =
            rawStatus.charAt(0).toUpperCase() + rawStatus.slice(1).toLowerCase();

          return {
            id: order.id?.toString() ?? "",
            number:
              order.sale_number?.toString() ??
              order.id?.toString() ??
              group.label,
            title: this.documentTitleFromType(order.document_type),
            status: status,
            amount: total,
            date:
              order.sale_date?.toString() ?? order.created_at?.toString() ?? null,
            location: order.place_of_supply?.toString() ?? "-",
            orderNumber: null,
            referenceNumber: order.reference?.toString() ?? "-",
            paymentMode: null,
            balanceDue: total,
            unusedAmount: null,
            dueDate: null,
            shipmentDate: null,
            trackingNumber: null,
            vendorName: null,
            lineItemsTotal: null,
          };
        });

      return {
        key: group.key,
        label: group.label,
        count: items.length,
        items,
      };
    });
  }

  private buildActivities(auditLogs: any[]): CustomerDetailActivityDto[] {
    return auditLogs.slice(0, 25).map((log: any) => ({
      id: log.id?.toString() ?? "",
      actor: log.actor_name?.toString().trim() || "System",
      action: log.action?.toString() ?? "updated",
      description: this.describeAuditLog(log),
      createdAt: log.created_at?.toString() ?? null,
    }));
  }

  private buildComments(): CustomerDetailCommentDto[] {
    return [];
  }

  private buildMails(): CustomerDetailMailDto[] {
    return [];
  }

  private buildStatementEntries(
    customer: any,
    salesOrders: any[],
    salesPayments: any[],
  ): CustomerStatementEntryDto[] {
    const events: Array<{
      id: string;
      date: string | null;
      type: string;
      number: string;
      reference: string | null;
      status: string | null;
      debit: number;
      credit: number;
    }> = [];

    const openingBalance = Number(customer.opening_balance ?? 0);
    if (openingBalance !== 0) {
      events.push({
        id: "opening-balance",
        date: customer.created_at?.toString?.() ?? null,
        type: "Opening Balance",
        number: "Opening Balance",
        reference: null,
        status: null,
        debit: openingBalance > 0 ? openingBalance : 0,
        credit: openingBalance < 0 ? Math.abs(openingBalance) : 0,
      });
    }

    for (const order of salesOrders) {
      const amount = Number(order.total ?? 0);
      if (
        order.document_type === "invoice" ||
        order.document_type === "retainer_invoice" ||
        order.document_type === "recurring_invoice"
      ) {
        events.push({
          id: order.id?.toString() ?? "",
          date:
            order.sale_date?.toString() ?? order.created_at?.toString() ?? null,
          type: this.documentTitleFromType(order.document_type),
          number:
            order.sale_number?.toString() ?? order.id?.toString() ?? "Document",
          reference: order.reference?.toString() ?? null,
          status: order.status?.toString() ?? null,
          debit: amount,
          credit: 0,
        });
      } else if (order.document_type === "credit_note") {
        events.push({
          id: order.id?.toString() ?? "",
          date:
            order.sale_date?.toString() ?? order.created_at?.toString() ?? null,
          type: "Credit Note",
          number:
            order.sale_number?.toString() ??
            order.id?.toString() ??
            "Credit Note",
          reference: order.reference?.toString() ?? null,
          status: order.status?.toString() ?? null,
          debit: 0,
          credit: amount,
        });
      }
    }

    for (const payment of salesPayments) {
      events.push({
        id: payment.id?.toString() ?? "",
        date:
          payment.payment_date?.toString() ??
          payment.created_at?.toString() ??
          null,
        type: "Customer Payment",
        number: payment.payment_number?.toString() ?? "Payment",
        reference: payment.reference?.toString() ?? null,
        status: "Recorded",
        debit: 0,
        credit: Number(payment.amount ?? 0),
      });
    }

    events.sort((a, b) => {
      const finalA = a.date ? new Date(a.date).getTime() : 0;
      const finalB = b.date ? new Date(b.date).getTime() : 0;
      return finalA - finalB;
    });

    let runningBalance = 0;
    return events.map((event) => {
      runningBalance += event.debit - event.credit;
      return {
        ...event,
        balance: Number(runningBalance.toFixed(2)),
      };
    });
  }

  private documentTitleFromType(type: string | null | undefined): string {
    switch (type) {
      case "invoice":
        return "Invoice";
      case "retainer_invoice":
        return "Retainer Invoice";
      case "recurring_invoice":
        return "Recurring Invoice";
      case "order":
        return "Sales Order";
      case "quote":
        return "Quotation";
      case "challan":
        return "Delivery Challan";
      case "credit_note":
        return "Credit Note";
      default:
        return "Sales Document";
    }
  }

  private describeAuditLog(log: any): string {
    const action = log.action?.toString().toLowerCase() ?? "updated";
    const table = log.table_name?.toString() ?? "";
    const label =
      table === "customers"
        ? "customer"
        : table === "sales_orders"
          ? this.documentTitleFromType(
              log.new_values?.document_type ?? log.old_values?.document_type,
            ).toLowerCase()
          : table === "sales_payments"
            ? "customer payment"
            : "record";

    if (action === "insert" || action === "created") {
      return `Created ${label}.`;
    }
    if (action === "delete" || action === "deleted") {
      return `Deleted ${label}.`;
    }

    const changedColumns = Array.isArray(log.changed_columns)
      ? log.changed_columns.filter(Boolean)
      : [];
    if (changedColumns.length > 0) {
      return `Updated ${label}: ${changedColumns.slice(0, 3).join(", ")}.`;
    }

    return `Updated ${label}.`;
  }
}
