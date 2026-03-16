import { Injectable } from "@nestjs/common";
import { SupabaseService } from "../../supabase/supabase.service";
import { R2StorageService } from "../../accountant/r2-storage.service";

@Injectable()
export class CustomersService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly r2StorageService: R2StorageService,
  ) {}

  async findAll(page: number = 1, limit: number = 100, _search?: string) {
    const offset = (page - 1) * limit;

    // Simple query without complex chaining for now
    const { data, error, count } = await this.supabaseService
      .getClient()
      .from("customers")
      .select("*", { count: "exact" })
      .range(offset, offset + limit - 1);

    if (error) {
      throw new Error(`Failed to fetch customers: ${error.message}`);
    }

    return {
      data: data ? await Promise.all(data.map((c) => this.mapCustomer(c))) : [],
      total: count || 0,
    };
  }

  async findOne(id: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("customers")
      .select("*")
      .eq("id", id)
      .single();

    if (error) {
      return null;
    }

    return this.mapCustomer(data);
  }

  async create(createCustomerDto: any) {
    // Map camelCase DTO fields to snake_case database columns
    const customerData = {
      // Basic Info
      customer_type: createCustomerDto.customerType,
      customer_number: createCustomerDto.customerNumber,
      salutation: createCustomerDto.salutation,
      first_name: createCustomerDto.firstName,
      last_name: createCustomerDto.lastName,
      company_name: createCustomerDto.companyName,
      display_name: createCustomerDto.displayName,

      // Contact Info
      email: createCustomerDto.email,
      phone: createCustomerDto.phone,
      mobile_phone: createCustomerDto.mobilePhone,
      website: createCustomerDto.website,
      designation: createCustomerDto.designation,
      department: createCustomerDto.department,
      business_type: createCustomerDto.businessType,
      customer_language: createCustomerDto.customerLanguage || "English",

      // Individual Customer Fields
      date_of_birth: createCustomerDto.dateOfBirth,
      age: createCustomerDto.age,
      gender: createCustomerDto.gender,
      place_of_customer: createCustomerDto.placeOfCustomer,
      privilege_card_number: createCustomerDto.privilegeCardNumber,
      parent_customer_id: createCustomerDto.parentCustomerId,

      // Billing Address (individual fields)
      billing_address_street1: createCustomerDto.billingAddress?.street1,
      billing_address_street2: createCustomerDto.billingAddress?.street2,
      billing_address_city: createCustomerDto.billingAddress?.city,
      billing_address_state_id: createCustomerDto.billingAddress?.stateId,
      billing_address_zip: createCustomerDto.billingAddress?.zip,
      billing_address_country_id: createCustomerDto.billingAddress?.countryId,
      billing_address_phone: createCustomerDto.billingAddress?.phone,

      // Shipping Address (individual fields)
      shipping_address_street1: createCustomerDto.shippingAddress?.street1,
      shipping_address_street2: createCustomerDto.shippingAddress?.street2,
      shipping_address_city: createCustomerDto.shippingAddress?.city,
      shipping_address_state_id: createCustomerDto.shippingAddress?.stateId,
      shipping_address_zip: createCustomerDto.shippingAddress?.zip,
      shipping_address_country_id: createCustomerDto.shippingAddress?.countryId,
      shipping_address_phone: createCustomerDto.shippingAddress?.phone,

      // Tax & Regulatory
      gst_treatment: createCustomerDto.gstTreatment,
      gstin: createCustomerDto.gstin,
      pan: createCustomerDto.pan,
      place_of_supply: createCustomerDto.placeOfSupply,
      tax_preference: createCustomerDto.taxPreference,
      exemption_reason: createCustomerDto.exemptionReason,

      // License Details
      is_drug_registered: createCustomerDto.isDrugRegistered,
      is_fssai_registered: createCustomerDto.isFssaiRegistered,
      is_msme_registered: createCustomerDto.isMsmeRegistered,
      drug_licence_type: createCustomerDto.drugLicenceType,
      drug_license_20: createCustomerDto.drugLicense20,
      drug_license_21: createCustomerDto.drugLicense21,
      drug_license_20b: createCustomerDto.drugLicense20B,
      drug_license_21b: createCustomerDto.drugLicense21B,
      fssai: createCustomerDto.fssai,
      msme_registration_type: createCustomerDto.msmeRegistrationType,
      msme_number: createCustomerDto.msmeNumber,

      // License Document URLs
      drug_license_20_doc_url: createCustomerDto.drugLicense20DocUrl,
      drug_license_21_doc_url: createCustomerDto.drugLicense21DocUrl,
      drug_license_20b_doc_url: createCustomerDto.drugLicense20BDocUrl,
      drug_license_21b_doc_url: createCustomerDto.drugLicense21BDocUrl,
      fssai_doc_url: createCustomerDto.fssaiDocUrl,
      msme_doc_url: createCustomerDto.msmeDocUrl,
      document_urls: createCustomerDto.documentUrls,

      // Financial
      currency_id: createCustomerDto.currencyId,
      opening_balance: createCustomerDto.openingBalance || 0,
      credit_limit: createCustomerDto.creditLimit,
      payment_terms: createCustomerDto.paymentTerms,
      price_list_id: createCustomerDto.priceListId,
      receivable_balance: createCustomerDto.receivableBalance || 0,

      // Social & CRM
      enable_portal: createCustomerDto.enablePortal || false,
      facebook_handle: createCustomerDto.facebookHandle,
      twitter_handle: createCustomerDto.twitterHandle,
      whatsapp_number: createCustomerDto.whatsappNumber,
      is_recurring: createCustomerDto.isRecurring || false,

      // Metadata
      remarks: createCustomerDto.remarks,
      status: "active",
    };

    const { data: customer, error: customerError } = await this.supabaseService
      .getClient()
      .from("customers")
      .insert(customerData)
      .select()
      .single();

    if (customerError) {
      throw new Error(`Failed to create customer: ${customerError.message}`);
    }

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

      console.log("--- Inserting Contact Persons ---");
      console.log(JSON.stringify(contactsData, null, 2));

      const { error: contactsError } = await this.supabaseService
        .getClient()
        .from("customer_contact_persons")
        .insert(contactsData);

      if (contactsError) {
        console.error(
          `Failed to save contact persons: ${contactsError.message}`,
        );
        // Throwing error here will ensure the controller catches it
        // and doesn't return 201 if contacts fail.
        throw new Error(
          `Failed to save contact persons: ${contactsError.message}`,
        );
      }
    }

    return this.mapCustomer(customer);
  }

  async update(id: string, updateCustomerDto: any) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("customers")
      .update(updateCustomerDto)
      .eq("id", id)
      .select()
      .single();

    if (error) {
      return null;
    }

    return this.mapCustomer(data);
  }

  async remove(id: string) {
    // 1. Fetch document fields for R2 cleanup
    const customer = await this.findOne(id);
    if (!customer) return false;

    const { error } = await this.supabaseService
      .getClient()
      .from("customers")
      .delete()
      .eq("id", id);

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

  async getStatistics() {
    const { data: totalCustomers } = await this.supabaseService
      .getClient()
      .from("customers")
      .select("*", { count: "exact" });

    const { data: activeCustomers } = await this.supabaseService
      .getClient()
      .from("customers")
      .select("*", { count: "exact" })
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
}
