import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreateVendorDto } from "../dto/create-vendor.dto";
import { UpdateVendorDto } from "../dto/update-vendor.dto";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";

@Injectable()
export class VendorsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private mapVendorAddresses(vendor: any): any {
    if (!vendor) return vendor;

    const billing = vendor.vendor_addresses?.find(
      (address: any) =>
        address.address_type === "billing" || address.is_default_billing,
    );
    const shipping = vendor.vendor_addresses?.find(
      (address: any) =>
        address.address_type === "shipping" || address.is_default_shipping,
    );

    return {
      ...vendor,
      billing_attention:
        billing?.attention ?? vendor.billing_attention ?? null,
      billing_address_street:
        billing?.address_street ?? vendor.billing_address_street ?? null,
      billing_address_place:
        billing?.address_place ?? vendor.billing_address_place ?? null,
      billing_city: billing?.city ?? vendor.billing_city ?? null,
      billing_state: billing?.state ?? vendor.billing_state ?? null,
      billing_pincode: billing?.pincode ?? vendor.billing_pincode ?? null,
      billing_country_region:
        billing?.country_region ?? vendor.billing_country_region ?? null,
      billing_phone: billing?.phone ?? vendor.billing_phone ?? null,
      billing_fax: billing?.fax ?? vendor.billing_fax ?? null,
      shipping_attention:
        shipping?.attention ?? vendor.shipping_attention ?? null,
      shipping_address_street:
        shipping?.address_street ?? vendor.shipping_address_street ?? null,
      shipping_address_place:
        shipping?.address_place ?? vendor.shipping_address_place ?? null,
      shipping_city: shipping?.city ?? vendor.shipping_city ?? null,
      shipping_state: shipping?.state ?? vendor.shipping_state ?? null,
      shipping_pincode: shipping?.pincode ?? vendor.shipping_pincode ?? null,
      shipping_country_region:
        shipping?.country_region ?? vendor.shipping_country_region ?? null,
      shipping_phone: shipping?.phone ?? vendor.shipping_phone ?? null,
      shipping_fax: shipping?.fax ?? vendor.shipping_fax ?? null,
    };
  }

  async findAll(
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    search?: string,
  ) {
    const offset = (page - 1) * limit;

    let query = this.supabaseService
      .getClient()
      .from("vendors")
      .select(
        "*, vendor_addresses(*), vendor_contact_persons(*), vendor_bank_accounts(*)",
        { count: "exact" },
      );

    let isStarlexBranch = false;
    if (tenant.branchId) {
      const { data: obm } = await this.supabaseService
        .getClient()
        .from("organisation_branch_master")
        .select("parent_id")
        .eq("id", tenant.entityId)
        .maybeSingle();
      if (obm && obm.parent_id === "66d79887-be98-40ab-ac40-9e0a008f9d8a") {
        isStarlexBranch = true;
      }
    }

    if (isStarlexBranch) {
      query = query.or(`entity_id.eq.${tenant.entityId},id.eq.db013159-6ac3-49a6-95b1-eaec10f964db`);
    } else {
      query = query.eq("entity_id", tenant.entityId);
      if (tenant.entityId === "66d79887-be98-40ab-ac40-9e0a008f9d8a") {
        query = query.neq("id", "db013159-6ac3-49a6-95b1-eaec10f964db");
      }
    }

    query = query.range(offset, offset + limit - 1);

    if (search) {
      query = query.or(
        `display_name.ilike.%${search}%,company_name.ilike.%${search}%`,
      );
    }

    const { data, error, count } = await query;

    if (error) {
      throw new Error(`Failed to fetch vendors: ${error.message}`);
    }

    return {
      data: data?.map((vendor) => this.mapVendorAddresses(vendor)) ?? [],
      meta: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    let query = this.supabaseService
      .getClient()
      .from("vendors")
      .select(
        `
        *,
        vendor_addresses(*),
        vendor_contact_persons(*),
        vendor_bank_accounts(*)
      `,
      )
      .eq("id", id);

    let isStarlex = false;
    if (id === "db013159-6ac3-49a6-95b1-eaec10f964db") {
      const { data: obm } = await this.supabaseService
        .getClient()
        .from("organisation_branch_master")
        .select("parent_id")
        .eq("id", tenant.entityId)
        .maybeSingle();
      if (obm && (obm.parent_id === "66d79887-be98-40ab-ac40-9e0a008f9d8a" || tenant.entityId === "66d79887-be98-40ab-ac40-9e0a008f9d8a")) {
        isStarlex = true;
      }
    }

    if (isStarlex) {
      // Allow loading Starlex Healthcare Org Vendor from any of its branches
    } else {
      query = query.eq("entity_id", tenant.entityId);
    }

    const { data, error } = await query.single();

    if (error) {
      throw new NotFoundException(`Vendor with ID ${id} not found`);
    }

    return this.mapVendorAddresses(data);
  }

  async create(createVendorDto: CreateVendorDto, tenant: TenantContext) {
    const {
      billingAddress,
      shippingAddress,
      contactPersons,
      bankDetails,
      ...vendorFields
    } = createVendorDto;

    const displayName = vendorFields.displayName?.toString().trim() ?? "";
    const vendorNumber = vendorFields.vendorNumber?.toString().trim() ?? "";
    const firstName = vendorFields.firstName?.toString().trim() ?? "";
    const lastName = vendorFields.lastName?.toString().trim() ?? "";
    const companyName = vendorFields.companyName?.toString().trim() ?? "";

    if (!displayName) {
      throw new BadRequestException("Display name is required.");
    }

    if (!vendorNumber) {
      throw new BadRequestException("Vendor number is required.");
    }

    if (!companyName && !firstName && !lastName) {
      throw new BadRequestException(
        "Enter either a company name or a primary contact name.",
      );
    }

    const vendorData = {
      display_name: displayName,
      // vendor_type: vendorFields.vendorType,
      vendor_number: vendorNumber,
      salutation: vendorFields.salutation,
      first_name: firstName || null,
      last_name: lastName || null,
      company_name: companyName || null,
      email: vendorFields.email,
      phone: vendorFields.phone,
      mobile_phone: vendorFields.mobilePhone,
      designation: vendorFields.designation,
      department: vendorFields.department,
      website: vendorFields.website,
      vendor_language: vendorFields.vendorLanguage,
      gst_treatment: vendorFields.gstTreatment,
      gstin: vendorFields.gstin,
      source_of_supply: vendorFields.sourceOfSupply,
      pan: vendorFields.pan,
      // tax_preference: vendorFields.taxPreference,
      // exemption_reason: vendorFields.exemptionReason,
      // drug_license_no: vendorFields.drugLicenseNo,
      currency: vendorFields.currency,
      payment_terms: vendorFields.paymentTerms,
      price_list_id: vendorFields.priceListId,
      is_msme_registered: vendorFields.isMsmeRegistered,
      msme_registration_type: vendorFields.msmeRegistrationType,
      msme_registration_number: vendorFields.msmeRegistrationNumber,
      is_drug_registered: vendorFields.isDrugRegistered,
      drug_licence_type: vendorFields.drugLicenceType,
      drug_license_20: vendorFields.drugLicense20,
      drug_license_21: vendorFields.drugLicense21,
      drug_license_20b: vendorFields.drugLicense20b,
      drug_license_21b: vendorFields.drugLicense21b,
      is_fssai_registered: vendorFields.isFssaiRegistered,
      fssai_number: vendorFields.fssaiNumber,
      tds_rate_id: vendorFields.tdsRateId,
      enable_portal: vendorFields.enablePortal,
      remarks: vendorFields.remarks,
      x_handle: vendorFields.xHandle,
      facebook_handle: vendorFields.facebookHandle,
      whatsapp_number: vendorFields.whatsappNumber,
      source: vendorFields.source,
      is_active:
        vendorFields.isActive !== undefined ? vendorFields.isActive : true,
      entity_id: tenant.entityId,
    };

    const client = this.supabaseService.getClient();

    // 1. Create Vendor
    const { data: vendor, error: vendorError } = await client
      .from("vendors")
      .insert([vendorData])
      .select()
      .single();

    if (vendorError) {
      console.error("❌ Supabase Error creating vendor:", vendorError);
      console.error("Payload that caused error:", vendorData);
      throw new BadRequestException(
        `Failed to create vendor: ${vendorError.message}`,
      );
    }

    const vendorId = vendor.id;

    // 2. Insert canonical address rows
    const addresses = [];
    if (
      billingAddress &&
      (billingAddress.attention ||
        billingAddress.street1 ||
        billingAddress.street ||
        billingAddress.city)
    ) {
      addresses.push({
        entity_id: tenant.entityId,
        vendor_id: vendorId,
        address_type: "billing",
        attention: billingAddress.attention ?? null,
        address_street:
          billingAddress.street ?? billingAddress.street1 ?? null,
        address_place: billingAddress.place ?? billingAddress.street2 ?? null,
        city: billingAddress.city ?? null,
        state: billingAddress.state ?? null,
        pincode: billingAddress.zip ?? null,
        country_region: billingAddress.country ?? "India",
        phone: billingAddress.phone ?? null,
        fax: billingAddress.fax ?? null,
        email: billingAddress.email ?? null,
        mobile: billingAddress.mobile ?? null,
        gstin: billingAddress.gstin ?? null,
        gst_treatment: billingAddress.gstTreatment ?? null,
        is_default_billing: true,
        is_default_shipping: false,
        is_active: true,
      });
    }

    if (
      shippingAddress &&
      (shippingAddress.attention ||
        shippingAddress.street1 ||
        shippingAddress.street ||
        shippingAddress.city)
    ) {
      addresses.push({
        entity_id: tenant.entityId,
        vendor_id: vendorId,
        address_type: "shipping",
        attention: shippingAddress.attention ?? null,
        address_street:
          shippingAddress.street ?? shippingAddress.street1 ?? null,
        address_place: shippingAddress.place ?? shippingAddress.street2 ?? null,
        city: shippingAddress.city ?? null,
        state: shippingAddress.state ?? null,
        pincode: shippingAddress.zip ?? null,
        country_region: shippingAddress.country ?? "India",
        phone: shippingAddress.phone ?? null,
        fax: shippingAddress.fax ?? null,
        email: shippingAddress.email ?? null,
        mobile: shippingAddress.mobile ?? null,
        gstin: shippingAddress.gstin ?? null,
        gst_treatment: shippingAddress.gstTreatment ?? null,
        is_default_billing: false,
        is_default_shipping: true,
        is_active: true,
      });
    }

    if (addresses.length > 0) {
      const { error: addressError } = await client
        .from("vendor_addresses")
        .insert(addresses);
      if (addressError) {
        console.error(
          "❌ Supabase Error creating vendor addresses:",
          addressError,
        );
      }
    }

    // 3. Insert Contacts
    if (contactPersons && contactPersons.length > 0) {
      const contacts = contactPersons.map((c) => ({
        vendor_id: vendorId,
        salutation: c.salutation,
        first_name: c.firstName,
        last_name: c.lastName,
        email: c.email,
        work_phone: c.workPhone,
        mobile_phone: c.mobilePhone,
        designation: c.designation,
        department: c.department,
      }));
      await client.from("vendor_contact_persons").insert(contacts);
    }

    // 4. Insert Banks
    if (bankDetails && bankDetails.length > 0) {
      const banks = bankDetails.map((b) => ({
        vendor_id: vendorId,
        holder_name: b.holderName,
        bank_name: b.bankName,
        account_number: b.accountNumber,
        ifsc: b.ifsc,
      }));
      await client.from("vendor_bank_accounts").insert(banks);
    }

    // 5. Create or update vendor account in accounts table
    try {
      const vendorAccountName = displayName || companyName || `${firstName} ${lastName}`.trim() || vendorNumber;
      const vendorRemarks = vendorFields.remarks?.toString().trim() || null;
      const vendorCurrency = vendorFields.currency?.toString().trim() || 'INR';

      const { data: existingAccount } = await client
        .from("accounts")
        .select("id")
        .eq("entity_id", tenant.entityId)
        .eq("account_type", "Accounts Payable")
        .or(`system_account_name.eq.${vendorAccountName},user_account_name.eq.${vendorAccountName}`)
        .maybeSingle();

      if (!existingAccount) {
        await client.from("accounts").insert({
          system_account_name: vendorAccountName,
          user_account_name: vendorAccountName,
          account_type: "Accounts Payable",
          account_group: "Liabilities",
          account_code: vendorNumber || null,
          description: vendorRemarks,
          currency: vendorCurrency,
          is_active: true,
          is_system: false,
          is_deletable: true,
          show_in_zerpai_expense: false,
          is_deleted: false,
          entity_id: tenant.entityId,
          org_id: tenant.orgId || "00000000-0000-0000-0000-000000000000",
        });
      } else {
        await client.from("accounts").update({
          description: vendorRemarks,
          currency: vendorCurrency,
        }).eq("id", existingAccount.id);
      }
    } catch (accErr) {
      console.error("⚠️ Failed to sync vendor account in accounts table:", accErr);
    }

    return this.findOne(vendorId, tenant);
  }

  async update(
    id: string,
    updateVendorDto: UpdateVendorDto,
    tenant: TenantContext,
  ) {
    const {
      billingAddress,
      shippingAddress,
      contactPersons,
      bankDetails,
      ...vendorFields
    } = updateVendorDto as any;

    const fieldMapping: Record<string, string> = {
      displayName: "display_name",
      // vendorType: "vendor_type",
      vendorNumber: "vendor_number",
      salutation: "salutation",
      firstName: "first_name",
      lastName: "last_name",
      companyName: "company_name",
      email: "email",
      phone: "phone",
      mobilePhone: "mobile_phone",
      designation: "designation",
      department: "department",
      website: "website",
      vendorLanguage: "vendor_language",
      gstTreatment: "gst_treatment",
      gstin: "gstin",
      sourceOfSupply: "source_of_supply",
      pan: "pan",
      // taxPreference: "tax_preference",
      // exemptionReason: "exemption_reason",
      // drugLicenseNo: "drug_license_no",
      currency: "currency",
      paymentTerms: "payment_terms",
      priceListId: "price_list_id",
      isMsmeRegistered: "is_msme_registered",
      msmeRegistrationType: "msme_registration_type",
      msmeRegistrationNumber: "msme_registration_number",
      isDrugRegistered: "is_drug_registered",
      drugLicenceType: "drug_licence_type",
      drugLicense20: "drug_license_20",
      drugLicense21: "drug_license_21",
      drugLicense20b: "drug_license_20b",
      drugLicense21b: "drug_license_21b",
      isFssaiRegistered: "is_fssai_registered",
      fssaiNumber: "fssai_number",
      tdsRateId: "tds_rate_id",
      enablePortal: "enable_portal",
      isActive: "is_active",
      remarks: "remarks",
      xHandle: "x_handle",
      facebookHandle: "facebook_handle",
      whatsappNumber: "whatsapp_number",
    };

    const updateData: any = {
      updated_at: new Date(),
    };



    for (const [key, value] of Object.entries(vendorFields)) {
      if (fieldMapping[key]) {
        updateData[fieldMapping[key]] = value;
      }
    }

    const client = this.supabaseService.getClient();

    let isStarlex = false;
    if (id === "db013159-6ac3-49a6-95b1-eaec10f964db") {
      const { data: obm } = await client
        .from("organisation_branch_master")
        .select("parent_id")
        .eq("id", tenant.entityId)
        .maybeSingle();
      if (obm && (obm.parent_id === "66d79887-be98-40ab-ac40-9e0a008f9d8a" || tenant.entityId === "66d79887-be98-40ab-ac40-9e0a008f9d8a")) {
        isStarlex = true;
      }
    }

    const targetEntityId = isStarlex ? "66d79887-be98-40ab-ac40-9e0a008f9d8a" : tenant.entityId;

    // 1. Update main table
    let updateQuery = client
      .from("vendors")
      .update(updateData)
      .eq("id", id);

    if (!isStarlex) {
      updateQuery = updateQuery.eq("entity_id", tenant.entityId);
    }

    const { data: vendor, error: vendorError } = await updateQuery
      .select()
      .single();

    if (vendorError) {
      throw new Error(`Failed to update vendor: ${vendorError.message}`);
    }

    if (billingAddress || shippingAddress) {
      await client
        .from("vendor_addresses")
        .delete()
        .eq("vendor_id", id)
        .in("address_type", ["billing", "shipping"]);

      const addresses = [];
      if (
        billingAddress &&
        (billingAddress.attention ||
          billingAddress.street1 ||
          billingAddress.street ||
          billingAddress.city)
      ) {
        addresses.push({
          entity_id: targetEntityId,
          vendor_id: id,
          address_type: "billing",
          attention: billingAddress.attention ?? null,
          address_street:
            billingAddress.street ?? billingAddress.street1 ?? null,
          address_place: billingAddress.place ?? billingAddress.street2 ?? null,
          city: billingAddress.city ?? null,
          state: billingAddress.state ?? null,
          pincode: billingAddress.zip ?? null,
          country_region: billingAddress.country ?? "India",
          phone: billingAddress.phone ?? null,
          fax: billingAddress.fax ?? null,
          email: billingAddress.email ?? null,
          mobile: billingAddress.mobile ?? null,
          gstin: billingAddress.gstin ?? null,
          gst_treatment: billingAddress.gstTreatment ?? null,
          is_default_billing: true,
          is_default_shipping: false,
          is_active: true,
        });
      }

      if (
        shippingAddress &&
        (shippingAddress.attention ||
          shippingAddress.street1 ||
          shippingAddress.street ||
          shippingAddress.city)
      ) {
        addresses.push({
          entity_id: targetEntityId,
          vendor_id: id,
          address_type: "shipping",
          attention: shippingAddress.attention ?? null,
          address_street:
            shippingAddress.street ?? shippingAddress.street1 ?? null,
          address_place: shippingAddress.place ?? shippingAddress.street2 ?? null,
          city: shippingAddress.city ?? null,
          state: shippingAddress.state ?? null,
          pincode: shippingAddress.zip ?? null,
          country_region: shippingAddress.country ?? "India",
          phone: shippingAddress.phone ?? null,
          fax: shippingAddress.fax ?? null,
          email: shippingAddress.email ?? null,
          mobile: shippingAddress.mobile ?? null,
          gstin: shippingAddress.gstin ?? null,
          gst_treatment: shippingAddress.gstTreatment ?? null,
          is_default_billing: false,
          is_default_shipping: true,
          is_active: true,
        });
      }

      if (addresses.length > 0) {
        await client.from("vendor_addresses").insert(addresses);
      }
    }

    // 3. Update Contacts (Delete and re-insert for simplicity/consistency)
    if (contactPersons) {
      await client.from("vendor_contact_persons").delete().eq("vendor_id", id);
      const contacts = contactPersons.map((c) => ({
        vendor_id: id,
        salutation: c.salutation,
        first_name: c.firstName,
        last_name: c.lastName,
        email: c.email,
        work_phone: c.workPhone,
        mobile_phone: c.mobilePhone,
        designation: c.designation,
        department: c.department,
      }));
      await client.from("vendor_contact_persons").insert(contacts);
    }

    // 4. Update Banks (Delete and re-insert)
    if (bankDetails) {
      await client.from("vendor_bank_accounts").delete().eq("vendor_id", id);
      const banks = bankDetails.map((b) => ({
        vendor_id: id,
        holder_name: b.holderName,
        bank_name: b.bankName,
        account_number: b.accountNumber,
        ifsc: b.ifsc,
      }));
      await client.from("vendor_bank_accounts").insert(banks);
    }

    return this.findOne(id, tenant);
  }

  async remove(id: string, tenant: TenantContext) {
    const { error } = await this.supabaseService
      .getClient()
      .from("vendors")
      .delete()
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (error) {
      throw new Error(`Failed to delete vendor: ${error.message}`);
    }

    return { message: "Vendor deleted successfully" };
  }
}
