import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreateVendorDto } from "../dto/create-vendor.dto";
import { UpdateVendorDto } from "../dto/update-vendor.dto";

@Injectable()
export class VendorsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(page: number = 1, limit: number = 100, search?: string) {
    const offset = (page - 1) * limit;

    let query = this.supabaseService
      .getClient()
      .from("vendors")
      .select("*", { count: "exact" })
      .range(offset, offset + limit - 1);

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
      data,
      meta: {
        total: count,
        page,
        limit,
        totalPages: Math.ceil(count / limit),
      },
    };
  }

  async findOne(id: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("vendors")
      .select(
        `
        *,
        vendor_contact_persons(*),
        vendor_bank_accounts(*)
      `,
      )
      .eq("id", id)
      .single();

    if (error) {
      throw new NotFoundException(`Vendor with ID ${id} not found`);
    }

    return data;
  }

  async create(createVendorDto: CreateVendorDto) {
    const {
      billingAddress,
      shippingAddress,
      contactPersons,
      bankDetails,
      ...vendorFields
    } = createVendorDto;

    const vendorData = {
      display_name: vendorFields.displayName,
      // vendor_type: vendorFields.vendorType,
      vendor_number: vendorFields.vendorNumber,
      salutation: vendorFields.salutation,
      first_name: vendorFields.firstName,
      last_name: vendorFields.lastName,
      company_name: vendorFields.companyName,
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
      org_id: "00000000-0000-0000-0000-000000000000",
      // Flattened Address fields
      billing_attention: billingAddress?.attention,
      billing_address_street_1: billingAddress?.street1,
      billing_address_street_2: billingAddress?.street2,
      billing_city: billingAddress?.city,
      billing_state: billingAddress?.state,
      billing_pincode: billingAddress?.zip,
      billing_country_region: billingAddress?.country,
      billing_phone: billingAddress?.phone,
      billing_fax: billingAddress?.fax,
      shipping_attention: shippingAddress?.attention,
      shipping_address_street_1: shippingAddress?.street1,
      shipping_address_street_2: shippingAddress?.street2,
      shipping_city: shippingAddress?.city,
      shipping_state: shippingAddress?.state,
      shipping_pincode: shippingAddress?.zip,
      shipping_country_region: shippingAddress?.country,
      shipping_phone: shippingAddress?.phone,
      shipping_fax: shippingAddress?.fax,
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

    // 2. Insert Contacts
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

    // 3. Insert Banks
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

    return vendor;
  }

  async update(id: string, updateVendorDto: UpdateVendorDto) {
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

    // Flatten address fields in update as well
    if (billingAddress) {
      updateData.billing_attention = billingAddress.attention;
      updateData.billing_address_street_1 = billingAddress.street1;
      updateData.billing_address_street_2 = billingAddress.street2;
      updateData.billing_city = billingAddress.city;
      updateData.billing_state = billingAddress.state;
      updateData.billing_pincode = billingAddress.zip;
      updateData.billing_country_region = billingAddress.country;
      updateData.billing_phone = billingAddress.phone;
      updateData.billing_fax = billingAddress.fax;
    }
    if (shippingAddress) {
      updateData.shipping_attention = shippingAddress.attention;
      updateData.shipping_address_street_1 = shippingAddress.street1;
      updateData.shipping_address_street_2 = shippingAddress.street2;
      updateData.shipping_city = shippingAddress.city;
      updateData.shipping_state = shippingAddress.state;
      updateData.shipping_pincode = shippingAddress.zip;
      updateData.shipping_country_region = shippingAddress.country;
      updateData.shipping_phone = shippingAddress.phone;
      updateData.shipping_fax = shippingAddress.fax;
    }

    for (const [key, value] of Object.entries(vendorFields)) {
      if (fieldMapping[key]) {
        updateData[fieldMapping[key]] = value;
      }
    }

    const client = this.supabaseService.getClient();

    // 1. Update main table
    const { data: vendor, error: vendorError } = await client
      .from("vendors")
      .update(updateData)
      .eq("id", id)
      .select()
      .single();

    if (vendorError) {
      throw new Error(`Failed to update vendor: ${vendorError.message}`);
    }

    // 2. Update Contacts (Delete and re-insert for simplicity/consistency)
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

    // 3. Update Banks (Delete and re-insert)
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

    return vendor;
  }

  async remove(id: string) {
    const { error } = await this.supabaseService
      .getClient()
      .from("vendors")
      .delete()
      .eq("id", id);

    if (error) {
      throw new Error(`Failed to delete vendor: ${error.message}`);
    }

    return { message: "Vendor deleted successfully" };
  }
}
