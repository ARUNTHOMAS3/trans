import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { CreateVendorDto } from "../dto/create-vendor.dto";
import { UpdateVendorDto } from "../dto/update-vendor.dto";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { client } from "../../../../db/db";

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
    const numPage = Math.max(1, parseInt(page as any, 10) || 1);
    const numLimit = Math.max(1, Math.min(500, parseInt(limit as any, 10) || 100));
    const offset = (numPage - 1) * numLimit;

    let isStarlexBranch = false;
    if (tenant.branchId) {
      const obm = await client.unsafe(
        `SELECT parent_id FROM organisation_branch_master WHERE id = $1 LIMIT 1`,
        [tenant.entityId],
      );
      if (obm[0] && obm[0].parent_id === "66d79887-be98-40ab-ac40-9e0a008f9d8a") {
        isStarlexBranch = true;
      }
    }

    let sqlQuery = `SELECT * FROM vendors WHERE `;
    let countQuery = `SELECT COUNT(*)::int as count FROM vendors WHERE `;
    const params: any[] = [];

    if (isStarlexBranch) {
      sqlQuery += `(entity_id = $1 OR id = 'db013159-6ac3-49a6-95b1-eaec10f964db')`;
      countQuery += `(entity_id = $1 OR id = 'db013159-6ac3-49a6-95b1-eaec10f964db')`;
      params.push(tenant.entityId);
    } else {
      sqlQuery += `entity_id = $1`;
      countQuery += `entity_id = $1`;
      params.push(tenant.entityId);
      if (tenant.entityId === "66d79887-be98-40ab-ac40-9e0a008f9d8a") {
        sqlQuery += ` AND id != 'db013159-6ac3-49a6-95b1-eaec10f964db'`;
        countQuery += ` AND id != 'db013159-6ac3-49a6-95b1-eaec10f964db'`;
      }
    }

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      const sIdx = params.length;
      sqlQuery += ` AND (display_name ILIKE $${sIdx} OR company_name ILIKE $${sIdx})`;
      countQuery += ` AND (display_name ILIKE $${sIdx} OR company_name ILIKE $${sIdx})`;
    }

    sqlQuery += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    try {
      const [vendors, countRes] = await Promise.all([
        client.unsafe(sqlQuery, [...params, numLimit, offset]),
        client.unsafe(countQuery, params),
      ]);

      const totalCount = countRes[0]?.count ?? 0;

      for (const v of vendors ?? []) {
        const [addresses, contacts, bankAccounts] = await Promise.all([
          client.unsafe(`SELECT * FROM vendor_addresses WHERE vendor_id = $1`, [v.id]),
          client.unsafe(`SELECT * FROM vendor_contact_persons WHERE vendor_id = $1`, [v.id]),
          client.unsafe(`SELECT * FROM vendor_bank_accounts WHERE vendor_id = $1`, [v.id]),
        ]);
        v.vendor_addresses = addresses ?? [];
        v.vendor_contact_persons = contacts ?? [];
        v.vendor_bank_accounts = bankAccounts ?? [];
      }

      return {
        data: vendors?.map((vendor: any) => this.mapVendorAddresses(vendor)) ?? [],
        meta: {
          total: totalCount,
          page: numPage,
          limit: numLimit,
          totalPages: Math.ceil(totalCount / numLimit),
        },
      };
    } catch (error: any) {
      throw new Error(`Failed to fetch vendors: ${error.message}`);
    }
  }

  async findOne(id: string, tenant: TenantContext) {
    let isStarlex = false;
    if (id === "db013159-6ac3-49a6-95b1-eaec10f964db") {
      const obm = await client.unsafe(
        `SELECT parent_id FROM organisation_branch_master WHERE id = $1 LIMIT 1`,
        [tenant.entityId],
      );
      if (obm[0] && (obm[0].parent_id === "66d79887-be98-40ab-ac40-9e0a008f9d8a" || tenant.entityId === "66d79887-be98-40ab-ac40-9e0a008f9d8a")) {
        isStarlex = true;
      }
    }

    let sqlQuery = `SELECT * FROM vendors WHERE id = $1`;
    const params: any[] = [id];

    if (!isStarlex) {
      params.push(tenant.entityId);
      sqlQuery += ` AND entity_id = $2`;
    }
    sqlQuery += ` LIMIT 1`;

    const rows = await client.unsafe(sqlQuery, params);
    const data = rows[0];

    if (!data) {
      throw new NotFoundException(`Vendor with ID ${id} not found`);
    }

    const [addresses, contacts, bankAccounts] = await Promise.all([
      client.unsafe(`SELECT * FROM vendor_addresses WHERE vendor_id = $1`, [id]),
      client.unsafe(`SELECT * FROM vendor_contact_persons WHERE vendor_id = $1`, [id]),
      client.unsafe(`SELECT * FROM vendor_bank_accounts WHERE vendor_id = $1`, [id]),
    ]);

    data.vendor_addresses = addresses ?? [];
    data.vendor_contact_persons = contacts ?? [];
    data.vendor_bank_accounts = bankAccounts ?? [];

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

    const keys = Object.keys(vendorData);
    const cols = keys.map((k) => `"${k}"`).join(", ");
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");
    const values: any[] = Object.values(vendorData);

    let vendor: any;
    try {
      const rows = await client.unsafe(
        `INSERT INTO vendors (${cols}) VALUES (${placeholders}) RETURNING *`,
        values,
      );
      vendor = rows[0];
    } catch (vendorError: any) {
      throw new BadRequestException(
        `Failed to create vendor: ${vendorError.message}`,
      );
    }

    const vendorId = vendor.id;

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
      for (const addr of addresses) {
        const aKeys = Object.keys(addr);
        const aCols = aKeys.map((k) => `"${k}"`).join(", ");
        const aPlaceholders = aKeys.map((_, i) => `$${i + 1}`).join(", ");
        const aValues: any[] = Object.values(addr);

        await client.unsafe(
          `INSERT INTO vendor_addresses (${aCols}) VALUES (${aPlaceholders})`,
          aValues,
        );
      }
    }

    if (contactPersons && contactPersons.length > 0) {
      for (const c of contactPersons) {
        await client.unsafe(
          `INSERT INTO vendor_contact_persons (vendor_id, salutation, first_name, last_name, email, work_phone, mobile_phone, designation, department)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
          [
            vendorId,
            c.salutation ?? null,
            c.firstName ?? null,
            c.lastName ?? null,
            c.email ?? null,
            c.workPhone ?? null,
            c.mobilePhone ?? null,
            c.designation ?? null,
            c.department ?? null,
          ],
        );
      }
    }

    if (bankDetails && bankDetails.length > 0) {
      for (const b of bankDetails) {
        await client.unsafe(
          `INSERT INTO vendor_bank_accounts (vendor_id, holder_name, bank_name, account_number, ifsc)
           VALUES ($1, $2, $3, $4, $5)`,
          [
            vendorId,
            b.holderName ?? null,
            b.bankName ?? null,
            b.accountNumber ?? null,
            b.ifsc ?? null,
          ],
        );
      }
    }

    try {
      const vendorAccountName = displayName || companyName || `${firstName} ${lastName}`.trim() || vendorNumber;
      const vendorRemarks = vendorFields.remarks?.toString().trim() || null;
      const vendorCurrency = vendorFields.currency?.toString().trim() || 'INR';

      const existingAccount = await client.unsafe(
        `SELECT id FROM accounts
         WHERE entity_id = $1 AND account_type = 'Accounts Payable'
         AND (system_account_name = $2 OR user_account_name = $2) LIMIT 1`,
        [tenant.entityId, vendorAccountName],
      );

      let accountId = existingAccount[0]?.id;

      if (!existingAccount[0]) {
        const newAccRows = await client.unsafe(
          `INSERT INTO accounts (system_account_name, user_account_name, account_type, account_group, account_code, description, currency, is_active, is_system, is_deletable, show_in_zerpai_expense, is_deleted, entity_id, org_id)
           VALUES ($1, $1, 'Accounts Payable', 'Liabilities', $2, $3, $4, true, false, true, false, false, $5, $6)
           RETURNING id`,
          [
            vendorAccountName,
            vendorNumber || null,
            vendorRemarks,
            vendorCurrency,
            tenant.entityId,
            tenant.orgId || "00000000-0000-0000-0000-000000000000",
          ],
        );

        accountId = newAccRows[0]?.id;
      } else {
        await client.unsafe(
          `UPDATE accounts SET description = $1, currency = $2 WHERE id = $3`,
          [vendorRemarks, vendorCurrency, existingAccount[0].id],
        );
      }

      if (accountId) {
        await client.unsafe(
          `UPDATE vendors SET account_id = $1 WHERE id = $2`,
          [accountId, vendorId],
        );
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
      updated_at: new Date().toISOString(),
    };

    for (const [key, value] of Object.entries(vendorFields)) {
      if (fieldMapping[key]) {
        updateData[fieldMapping[key]] = value;
      }
    }

    let isStarlex = false;
    if (id === "db013159-6ac3-49a6-95b1-eaec10f964db") {
      const obm = await client.unsafe(
        `SELECT parent_id FROM organisation_branch_master WHERE id = $1 LIMIT 1`,
        [tenant.entityId],
      );
      if (obm[0] && (obm[0].parent_id === "66d79887-be98-40ab-ac40-9e0a008f9d8a" || tenant.entityId === "66d79887-be98-40ab-ac40-9e0a008f9d8a")) {
        isStarlex = true;
      }
    }

    const targetEntityId = isStarlex ? "66d79887-be98-40ab-ac40-9e0a008f9d8a" : tenant.entityId;

    const keys = Object.keys(updateData);
    const setClauses = keys.map((k, i) => `"${k}" = $${i + 1}`).join(", ");
    const values: any[] = Object.values(updateData);

    let sqlQuery = `UPDATE vendors SET ${setClauses} WHERE id = $${keys.length + 1}`;
    const queryParams = [...values, id];

    if (!isStarlex) {
      queryParams.push(tenant.entityId);
      sqlQuery += ` AND entity_id = $${queryParams.length}`;
    }
    sqlQuery += ` RETURNING *`;

    try {
      const rows = await client.unsafe(sqlQuery, queryParams);
      if (!rows[0]) throw new Error("Vendor not found or entity mismatch");
    } catch (vendorError: any) {
      throw new Error(`Failed to update vendor: ${vendorError.message}`);
    }

    if (billingAddress || shippingAddress) {
      await client.unsafe(
        `DELETE FROM vendor_addresses WHERE vendor_id = $1 AND address_type = ANY($2)`,
        [id, ["billing", "shipping"]],
      );

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
        for (const addr of addresses) {
          const aKeys = Object.keys(addr);
          const aCols = aKeys.map((k) => `"${k}"`).join(", ");
          const aPlaceholders = aKeys.map((_, i) => `$${i + 1}`).join(", ");
          const aValues: any[] = Object.values(addr);

          await client.unsafe(
            `INSERT INTO vendor_addresses (${aCols}) VALUES (${aPlaceholders})`,
            aValues,
          );
        }
      }
    }

    if (contactPersons) {
      await client.unsafe(`DELETE FROM vendor_contact_persons WHERE vendor_id = $1`, [id]);
      for (const c of contactPersons) {
        await client.unsafe(
          `INSERT INTO vendor_contact_persons (vendor_id, salutation, first_name, last_name, email, work_phone, mobile_phone, designation, department)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
          [
            id,
            c.salutation ?? null,
            c.firstName ?? null,
            c.lastName ?? null,
            c.email ?? null,
            c.workPhone ?? null,
            c.mobilePhone ?? null,
            c.designation ?? null,
            c.department ?? null,
          ],
        );
      }
    }

    if (bankDetails) {
      await client.unsafe(`DELETE FROM vendor_bank_accounts WHERE vendor_id = $1`, [id]);
      for (const b of bankDetails) {
        await client.unsafe(
          `INSERT INTO vendor_bank_accounts (vendor_id, holder_name, bank_name, account_number, ifsc)
           VALUES ($1, $2, $3, $4, $5)`,
          [
            id,
            b.holderName ?? null,
            b.bankName ?? null,
            b.accountNumber ?? null,
            b.ifsc ?? null,
          ],
        );
      }
    }

    return this.findOne(id, tenant);
  }

  async remove(id: string, tenant: TenantContext) {
    try {
      await client.unsafe(
        `DELETE FROM vendors WHERE id = $1 AND entity_id = $2`,
        [id, tenant.entityId],
      );
    } catch (error: any) {
      throw new Error(`Failed to delete vendor: ${error.message}`);
    }

    return { message: "Vendor deleted successfully" };
  }
}
