export interface Customer {
  id: string;

  // Basic Info
  customer_type: string;
  customer_number?: string;
  salutation?: string;
  first_name: string | null;
  last_name: string | null;
  company_name: string | null;
  display_name: string;

  // Contact Info
  email: string | null;
  phone: string | null;
  mobile_phone?: string | null;
  website: string | null;
  designation?: string | null;
  department?: string | null;
  business_type?: string | null;
  customer_language?: string;

  // Individual Customer Fields
  date_of_birth?: Date | null;
  age?: number | null;
  gender?: string | null;
  place_of_customer?: string | null;
  privilege_card_number?: string | null;
  parent_customer_id?: string | null;

  // Addresses
  billing_address: any | null;
  shipping_address: any | null;

  // Tax & Regulatory
  gst_treatment: string | null;
  gstin: string | null;
  pan: string | null;
  place_of_supply: string | null;
  tax_preference?: string | null;
  exemption_reason?: string | null;

  // License Details
  drug_licence_type?: string | null;
  drug_license_20?: string | null;
  drug_license_21?: string | null;
  drug_license_20b?: string | null;
  drug_license_21b?: string | null;
  fssai?: string | null;
  msme_registration_type?: string | null;
  msme_number?: string | null;
  shop_establishment?: string | null;
  other_license?: string | null;

  // License Document URLs
  drug_license_20_doc_url?: string | null;
  drug_license_21_doc_url?: string | null;
  drug_license_20b_doc_url?: string | null;
  drug_license_21b_doc_url?: string | null;
  fssai_doc_url?: string | null;
  msme_doc_url?: string | null;

  // Financial
  currency: string;
  opening_balance?: number;
  credit_limit?: number | null;
  payment_terms: string | null;
  price_list_id: string | null;
  receivable_balance: number;

  // Social & CRM
  enable_portal?: boolean;
  facebook_handle?: string | null;
  twitter_handle?: string | null;
  whatsapp_number?: string | null;
  is_recurring?: boolean;

  // Metadata
  remarks: string | null;
  status: string;
  created_at: Date;
  updated_at: Date;
}
