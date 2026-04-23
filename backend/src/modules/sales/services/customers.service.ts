import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../../supabase/supabase.service";
import { R2StorageService } from "../../accountant/r2-storage.service";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { SequencesService } from "../../../sequences/sequences.service";
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

  async findAll(
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    _search?: string,
  ) {
    const offset = (page - 1) * limit;

    const { data, error, count } = await this.supabaseService
      .getClient()
      .from("customers")
      .select("*", { count: "exact" })
      .eq("entity_id", tenant.entityId)
      .range(offset, offset + limit - 1);

    if (error) {
      throw new Error(`Failed to fetch customers: ${error.message}`);
    }

    return {
      data: data ? await Promise.all(data.map((c) => this.mapCustomer(c))) : [],
      total: count || 0,
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("customers")
      .select("*")
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .single();

    if (error) {
      return null;
    }

    return this.mapCustomer(data);
  }

  async getDetailContext(
    id: string,
    tenant: TenantContext,
  ): Promise<CustomerDetailContextDto | null> {
    const customer = await this.findOne(id, tenant);
    if (!customer) {
      return null;
    }

    const client = this.supabaseService.getClient();
    const [salesOrdersResult, salesPaymentsResult, auditLogsResult] =
      await Promise.all([
        client
          .from("sales_orders")
          .select(
            "id, sale_number, reference, sale_date, created_at, status, total, document_type",
          )
          .eq("customer_id", id)
          .eq("entity_id", tenant.entityId)
          .order("sale_date", { ascending: false }),
        client
          .from("sales_payments")
          .select(
            "id, payment_number, payment_date, payment_mode, reference, amount, notes, created_at",
          )
          .eq("customer_id", id)
          .eq("entity_id", tenant.entityId)
          .order("payment_date", { ascending: false }),
        client
          .from("audit_logs")
          .select(
            "id, table_name, record_id, action, actor_name, created_at, changed_columns, new_values, old_values",
          )
          .eq("entity_id", tenant.entityId)
          .in("table_name", ["customers", "sales_orders", "sales_payments"])
          .order("created_at", { ascending: false })
          .limit(200),
      ]);

    if (salesOrdersResult.error) {
      throw new Error(
        `Failed to fetch customer sales documents: ${salesOrdersResult.error.message}`,
      );
    }

    if (salesPaymentsResult.error) {
      throw new Error(
        `Failed to fetch customer payments: ${salesPaymentsResult.error.message}`,
      );
    }

    if (auditLogsResult.error) {
      throw new Error(
        `Failed to fetch customer activity logs: ${auditLogsResult.error.message}`,
      );
    }

    const salesOrders = salesOrdersResult.data ?? [];
    const salesPayments = salesPaymentsResult.data ?? [];
    const auditLogs = (auditLogsResult.data ?? []).filter((log: any) => {
      if (log.record_id === id && log.table_name === "customers") {
        return true;
      }
      const newCustomerId = log.new_values?.customer_id?.toString?.();
      const oldCustomerId = log.old_values?.customer_id?.toString?.();
      return newCustomerId === id || oldCustomerId === id;
    });

    return {
      transactions: this.buildTransactionGroups(salesOrders, salesPayments),
      activities: this.buildActivities(auditLogs),
      comments: this.buildComments(),
      mails: this.buildMails(),
      statementEntries: this.buildStatementEntries(customer, salesOrders, salesPayments),
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

    const { data: customer, error: customerError } = await this.supabaseService
      .getClient()
      .from("customers")
      .insert(customerData)
      .select()
      .single();

    if (customerError) {
      if (customerError.message.includes("customers_customer_number_key")) {
        throw new Error("Customer number already exists");
      }
      throw new Error(`Failed to create customer: ${customerError.message}`);
    }

    await this.sequencesService.incrementSequence(
      "customer",
      tenant,
      resolvedCustomerNumber,
    );

    // Insert contact persons if any
    if (
      createCustomerDto.contactPersons &&
      createCustomerDto.contactPersons.length > 0
    ) {
      const contactsData = createCustomerDto.contactPersons.map(
        (contact, index) => ({
          customer_id: customer.id,
          salutation: contact.salutation,
          first_name: contact.firstName,
          last_name: contact.lastName,
          email: contact.email,
          work_phone: contact.workPhone,
          mobile_phone: contact.mobilePhone,
          display_order: index,
        }),
      );

      const { error: contactsError } = await this.supabaseService
        .getClient()
        .from("customer_contact_persons")
        .insert(contactsData);

      if (contactsError) {
        console.error(
          `Failed to save contact persons: ${contactsError.message}`,
        );
        throw new Error(
          `Failed to save contact persons: ${contactsError.message}`,
        );
      }
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
        ? (updateCustomerDto.customerNumber?.toString().trim() || undefined)
        : undefined;

    const payload = this.buildCustomerWriteModel(updateCustomerDto, tenant, {
      resolvedCurrencyId,
      resolvedCustomerNumber,
      includeCreateDefaults: false,
    });

    const { data, error } = await this.supabaseService
      .getClient()
      .from("customers")
      .update(payload)
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .select()
      .single();

    if (error) {
      if (error.message.includes("customers_customer_number_key")) {
        throw new Error("Customer number already exists");
      }
      if (
        error.code == "PGRST116" ||
        error.message.toLowerCase().includes("no rows")
      ) {
        return null;
      }
      throw new Error(`Failed to update customer: ${error.message}`);
    }

    return this.mapCustomer(data);
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
      // Basic Info
      customer_type: dto.customerType,
      customer_number: options.resolvedCustomerNumber,
      salutation: dto.salutation,
      first_name: dto.firstName,
      last_name: dto.lastName,
      company_name: dto.companyName,
      display_name: dto.displayName,

      // Contact Info
      email: dto.email,
      phone: dto.phone,
      mobile_phone: dto.mobilePhone,
      website: dto.website,
      designation: dto.designation,
      department: dto.department,
      business_type: dto.businessType,
      customer_language: dto.customerLanguage,

      // Individual Customer Fields
      date_of_birth: dto.dateOfBirth,
      age: dto.age,
      gender: dto.gender,
      place_of_customer: dto.placeOfCustomer,
      privilege_card_number: dto.privilegeCardNumber,
      parent_customer_id: dto.parentCustomerId,

      // Billing Address
      billing_address_street:
        dto.billingAddress?.street1 ?? dto.billingAddress?.street,
      billing_address_place: dto.billingAddress?.place,
      billing_address_city: dto.billingAddress?.city,
      billing_address_state_id: dto.billingAddress?.stateId,
      billing_address_zip: dto.billingAddress?.zip,
      billing_address_country_id: dto.billingAddress?.countryId,
      billing_address_phone: dto.billingAddress?.phone,

      // Shipping Address
      shipping_address_street:
        dto.shippingAddress?.street1 ?? dto.shippingAddress?.street,
      shipping_address_place: dto.shippingAddress?.place,
      shipping_address_city: dto.shippingAddress?.city,
      shipping_address_state_id: dto.shippingAddress?.stateId,
      shipping_address_zip: dto.shippingAddress?.zip,
      shipping_address_country_id: dto.shippingAddress?.countryId,
      shipping_address_phone: dto.shippingAddress?.phone,

      // Tax & Regulatory
      gst_treatment: dto.gstTreatment,
      gstin: dto.gstin,
      pan: dto.pan,
      place_of_supply: dto.placeOfSupply,
      tax_preference: dto.taxPreference,
      exemption_reason: dto.exemptionReason,

      // License Details
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

      // License Documents
      drug_license_20_doc_url: dto.drugLicense20DocUrl,
      drug_license_21_doc_url: dto.drugLicense21DocUrl,
      drug_license_20b_doc_url: dto.drugLicense20BDocUrl,
      drug_license_21b_doc_url: dto.drugLicense21BDocUrl,
      fssai_doc_url: dto.fssaiDocUrl,
      msme_doc_url: dto.msmeDocUrl,
      document_urls: dto.documentUrls,

      // Financial
      currency_id: options.resolvedCurrencyId,
      opening_balance: dto.openingBalance,
      credit_limit: dto.creditLimit,
      payment_terms: dto.paymentTerms,
      price_list_id: dto.priceListId,
      receivable_balance: dto.receivableBalance,

      // Social & CRM
      enable_portal: dto.enablePortal,
      facebook_handle: dto.facebookHandle,
      twitter_handle: dto.twitterHandle,
      whatsapp_number: dto.whatsappNumber,
      is_recurring: dto.isRecurring,

      // Metadata
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
    // 1. Fetch document fields for R2 cleanup
    const customer = await this.findOne(id, tenant);
    if (!customer) return false;

    const { error } = await this.supabaseService
      .getClient()
      .from("customers")
      .delete()
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (!error) {
      // 2. Cleanup R2 Files
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
        // Only delete if it's a key (not a public URL)
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
    }

    return false;
  }

  async getStatistics(tenant: TenantContext) {
    const { data: totalCustomers } = await this.supabaseService
      .getClient()
      .from("customers")
      .select("*", { count: "exact" })
      .eq("entity_id", tenant.entityId);

    const { data: activeCustomers } = await this.supabaseService
      .getClient()
      .from("customers")
      .select("*", { count: "exact" })
      .eq("entity_id", tenant.entityId)
      .eq("status", "active");

    return {
      total: totalCustomers?.length || 0,
      active: activeCustomers?.length || 0,
      inactive: (totalCustomers?.length || 0) - (activeCustomers?.length || 0),
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

    return customer;
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

    const { data, error } = await this.supabaseService
      .getClient()
      .from("currencies")
      .select("id")
      .eq("code", trimmed.toUpperCase())
      .eq("is_active", true)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to resolve currency: ${error.message}`);
    }

    return data?.id ?? null;
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
  ): CustomerDetailTransactionGroupDto[] {
    const groups = [
      { key: "invoice", label: "Invoices" },
      { key: "payment", label: "Customer Payments" },
      { key: "retainer_invoice", label: "Retainer Invoices" },
      { key: "order", label: "Sales Orders" },
      { key: "challan", label: "Delivery Challans" },
      { key: "credit_note", label: "Credit Notes" },
      { key: "recurring_invoice", label: "Recurring Invoices" },
      { key: "payment_link", label: "Payment Links" },
    ];

    return groups.map((group) => {
      if (group.key === "payment") {
        const items = salesPayments.map((payment: any) => ({
          id: payment.id?.toString() ?? "",
          number: payment.payment_number?.toString() ?? "Payment",
          title: payment.notes?.toString().trim() || payment.payment_mode?.toString() || "Customer payment",
          status: "Recorded",
          amount: Number(payment.amount ?? 0),
          date: payment.payment_date?.toString() ?? payment.created_at?.toString() ?? null,
        }));

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
        .map((order: any) => ({
          id: order.id?.toString() ?? "",
          number: order.sale_number?.toString() ?? order.id?.toString() ?? group.label,
          title: this.documentTitleFromType(order.document_type),
          status: order.status?.toString() ?? "Draft",
          amount: Number(order.total ?? 0),
          date: order.sale_date?.toString() ?? order.created_at?.toString() ?? null,
        }));

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
      if (order.document_type === "invoice" || order.document_type === "retainer_invoice" || order.document_type === "recurring_invoice") {
        events.push({
          id: order.id?.toString() ?? "",
          date: order.sale_date?.toString() ?? order.created_at?.toString() ?? null,
          type: this.documentTitleFromType(order.document_type),
          number: order.sale_number?.toString() ?? order.id?.toString() ?? "Document",
          reference: order.reference?.toString() ?? null,
          status: order.status?.toString() ?? null,
          debit: amount,
          credit: 0,
        });
      } else if (order.document_type === "credit_note") {
        events.push({
          id: order.id?.toString() ?? "",
          date: order.sale_date?.toString() ?? order.created_at?.toString() ?? null,
          type: "Credit Note",
          number: order.sale_number?.toString() ?? order.id?.toString() ?? "Credit Note",
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
        date: payment.payment_date?.toString() ?? payment.created_at?.toString() ?? null,
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
          ? this.documentTitleFromType(log.new_values?.document_type ?? log.old_values?.document_type).toLowerCase()
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
