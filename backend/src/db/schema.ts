import { sql } from "drizzle-orm";
import {
  pgTable,
  uuid,
  varchar,
  text,
  boolean,
  integer,
  timestamp,
  pgEnum,
  jsonb,
  unique,
  index,
  check,
  date,
  numeric,
  smallint,
  bigint,
  decimal,
} from "drizzle-orm/pg-core";

// Enums
export const productTypeEnum = pgEnum("product_type", ["goods", "service"]);
export const taxPreferenceEnum = pgEnum("tax_preference", [
  "taxable",
  "non-taxable",
  "exempt",
]);
export const inventoryValuationMethodEnum = pgEnum(
  "inventory_valuation_method",
  ["FIFO", "LIFO", "FEFO", "Weighted Average", "Specific Identification"],
);
export const unitTypeEnum = pgEnum("unit_type", [
  "count",
  "weight",
  "volume",
  "length",
]);
export const taxTypeEnum = pgEnum("tax_type", ["IGST", "CGST", "SGST"]);
export const accountTypeEnum = pgEnum("account_type", [
  "sales",
  "purchase",
  "inventory",
  "expense",
  "asset",
]);
export const vendorTypeEnum = pgEnum("vendor_type", [
  "manufacturer",
  "distributor",
  "wholesaler",
]);
export const hsnSacTypeEnum = pgEnum("hsn_sac_type", ["HSN", "SAC"]);
export const branchTypeEnum = pgEnum("branch_type", ["FOFO", "COCO", "FRANCHISE", "WAREHOUSE"]);


// Unique Quantity Code (UQC) Table
export const uqc = pgTable("uqc", {
  id: uuid("id").primaryKey().defaultRandom(),
  uqcCode: varchar("uqc_code", { length: 20 }).notNull().unique(),
  description: varchar("description", { length: 255 }).notNull(),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Unit Table
export const unit = pgTable("units", {
  id: uuid("id").primaryKey().defaultRandom(),
  unitName: varchar("unit_name", { length: 50 }).notNull().unique(),
  unitSymbol: varchar("unit_symbol", { length: 10 }), // Maps to uqc.code
  uqcId: uuid("uqc_id").references(() => uqc.id),
  unitType: unitTypeEnum("unit_type"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Currency Table
export const currency = pgTable("currencies", {
  id: uuid("id").primaryKey().defaultRandom(),
  code: varchar("code", { length: 10 }).notNull().unique(),
  name: varchar("name", { length: 100 }).notNull(),
  symbol: varchar("symbol", { length: 10 }),
  decimals: integer("decimals").default(2),
  format: varchar("format", { length: 50 }),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Currency Denominations Table
export const currencyDenomination = pgTable("currency_denominations", {
  id: uuid("id").primaryKey().defaultRandom(),
  currencyId: uuid("currency_id")
    .notNull()
    .references(() => currency.id, { onDelete: "cascade" }),
  label: varchar("label", { length: 50 }).notNull(), // e.g. "500", "2000", "10"
  value: decimal("value", { precision: 15, scale: 2 }).notNull(),
  isCoin: boolean("is_coin").default(false),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Country Table
export const country = pgTable("countries", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 100 }).notNull().unique(),
  fullLabel: varchar("full_label", { length: 255 }), // e.g. "🇮🇳 India (+91)"
  phoneCode: varchar("phone_code", { length: 20 }).notNull(),
  shortCode: varchar("short_code", { length: 10 }), // e.g. "IN"
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Country Codes Table
export const countryCode = pgTable("country_codes", {
  id: uuid("id").primaryKey().defaultRandom(),
  countryName: varchar("country_name", { length: 150 }).notNull(),
  iso2: varchar("iso2", { length: 2 }).notNull().unique(), // e.g. "IN"
  iso3: varchar("iso3", { length: 3 }).notNull().unique(), // e.g. "IND"
  numericCode: varchar("numeric_code", { length: 5 }),
  phoneCode: varchar("phone_code", { length: 20 }),
  capital: varchar("capital", { length: 100 }),
  currencyCode: varchar("currency_code", { length: 10 }),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// States Table
export const state = pgTable(
  "states",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    name: varchar("name", { length: 255 }).notNull(),
    code: varchar("code", { length: 10 }), // State short code e.g. "TN"
    countryId: uuid("country_id").notNull(), // Links to countries.id
    isActive: boolean("is_active").default(true),
    createdAt: timestamp("created_at").defaultNow(),
  },
  (t) => [unique().on(t.name, t.countryId)],
);

// Cities Table
export const city = pgTable("cities", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull(),
  stateId: uuid("state_id")
    .notNull()
    .references(() => state.id, { onDelete: "cascade" }),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Category Table
export const category = pgTable("categories", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull().unique(),
  description: text("description"),
  parentId: uuid("parent_id").references(() => category.id),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Tax Rate Table
export const taxRate = pgTable("tax_rates", {
  id: uuid("id").primaryKey().defaultRandom(),
  taxName: varchar("tax_name", { length: 100 }).notNull().unique(),
  taxRate: decimal("tax_rate", { precision: 5, scale: 2 }).notNull(),
  taxType: taxTypeEnum("tax_type"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// TDS Rate Table
export const tdsRate = pgTable("tds_rates", {
  id: uuid("id").primaryKey().defaultRandom(),
  tdsName: varchar("tds_name", { length: 100 }).notNull().unique(),
  tdsRate: decimal("tds_rate", { precision: 5, scale: 2 }).notNull(),
  description: text("description"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Manufacturer Table
export const manufacturer = pgTable("manufacturers", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull().unique(),
  contactInfo: jsonb("contact_info"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Brand Table
export const brand = pgTable("brands", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull().unique(),
  manufacturerId: uuid("manufacturer_id").references(() => manufacturer.id),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Organization Table (Multi-tenancy Master)
export const organizations = pgTable("organization", {
  id: uuid("id").primaryKey().defaultRandom(),
  systemId: varchar("system_id", { length: 20 }).notNull(),
  name: varchar("name", { length: 255 }).notNull(),
  slug: varchar("slug", { length: 255 }).notNull().unique(),
  stateId: uuid("state_id"),
  industry: varchar("industry", { length: 255 }),
  logoUrl: text("logo_url"),
  baseCurrency: varchar("base_currency", { length: 10 }),
  baseCurrencyDecimals: smallint("base_currency_decimals"),
  baseCurrencyFormat: varchar("base_currency_format", { length: 50 }),
  fiscalYear: varchar("fiscal_year", { length: 50 }),
  reportBasis: varchar("report_basis", { length: 50 }).default("accrual"),
  organizationLanguage: varchar("organization_language", { length: 50 }),
  communicationLanguages: text("communication_languages").array(),
  timezone: varchar("timezone", { length: 100 }),
  dateFormat: varchar("date_format", { length: 50 }),
  dateSeparator: varchar("date_separator", { length: 5 }),
  companyIdLabel: varchar("company_id_label", { length: 50 }),
  companyIdValue: varchar("company_id_value", { length: 100 }),
  attention: text("attention"),
  street: text("street"),
  place: text("place"),
  city: varchar("city", { length: 100 }),
  pincode: varchar("pincode", { length: 20 }),
  phone: varchar("phone", { length: 50 }),
  
  // Compliance Fields
  isDrugRegistered: boolean("is_drug_registered").default(false),
  drugLicenceType: varchar("drug_licence_type", { length: 255 }),
  drugLicense20: varchar("drug_license_20", { length: 255 }),
  drugLicense21: varchar("drug_license_21", { length: 255 }),
  drugLicense20b: varchar("drug_license_20b", { length: 255 }),
  drugLicense21b: varchar("drug_license_21b", { length: 255 }),
  drugLicense20Url: text("drug_license_20_url"),
  drugLicense21Url: text("drug_license_21_url"),
  drugLicense20bUrl: text("drug_license_20b_url"),
  drugLicense21bUrl: text("drug_license_21b_url"),
  isFssaiRegistered: boolean("is_fssai_registered").default(false),
  fssaiNumber: varchar("fssai_number", { length: 255 }),
  fssaiUrl: text("fssai_url"),
  isMsmeRegistered: boolean("is_msme_registered").default(false),
  msmeRegistrationType: varchar("msme_registration_type", { length: 255 }),
  msmeNumber: varchar("msme_number", { length: 255 }),
  msmeUrl: text("msme_url"),

  // Address & LSGD Hierarchy
  paymentStubAddress: text("payment_stub_address"),
  additionalFields: jsonb("additional_fields"),
  hasSeparatePaymentStubAddress: boolean("has_separate_payment_stub_address").default(false),
  districtId: uuid("district_id"),
  localBodyId: uuid("local_body_id"),
  assemblyId: uuid("assembly_id").references(() => settingsAssemblies.id),
  wardId: uuid("ward_id"),
  paymentStubDistrictId: uuid("payment_stub_district_id"),
  paymentStubLocalBodyId: uuid("payment_stub_local_body_id"),
  paymentStubWardId: uuid("payment_stub_ward_id"),
  paymentStubAssemblyId: uuid("payment_stub_assembly_id").references(
    () => settingsAssemblies.id,
  ),

  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const organisationBranchMaster = pgTable("organisation_branch_master", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name").notNull(),
  type: varchar("type").notNull(), // 'ORG' or 'BRANCH'
  refId: uuid("ref_id").notNull(), // organization.id or branches.id
  parentId: uuid("parent_id"), // organization.id if branch
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});


export const settingsRoles = pgTable("roles", {
  id: uuid("id").primaryKey().defaultRandom(),
  label: varchar("label").notNull(),
  description: text("description").notNull().default(""),
  permissions: jsonb("permissions").notNull().default({}),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
});

export const warehouses = pgTable("warehouses", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: uuid("org_id"),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  branchId: uuid("branch_id"),
  name: varchar("name", { length: 255 }).notNull(),
  warehouseCode: varchar("warehouse_code", { length: 50 }),
  attention: text("attention"),
  street: text("street"),
  place: text("place"),
  city: text("city"),
  state: text("state"),
  districtId: uuid("district_id"),
  localBodyId: uuid("local_body_id"),
  assemblyId: uuid("assembly_id"),
  wardId: uuid("ward_id"),
  pincode: varchar("pincode", { length: 20 }),
  country: varchar("country", { length: 100 }).notNull().default("India"),
  phone: varchar("phone", { length: 50 }),
  email: varchar("email", { length: 255 }),
  isActive: boolean("is_active").default(true),
  customerId: uuid("customer_id").references(() => customer.id),
  vendorId: uuid("vendor_id").references(() => vendor.id),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const branchUserAccess = pgTable("branch_user_access", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id),
  roleId: uuid("role_id").references(() => settingsRoles.id),
  isDefaultBranch: boolean("is_default_branch").default(false),
  permissions: jsonb("permissions").default({}),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
});

// Account Table
export const account = pgTable("accounts", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: uuid("org_id")
    .notNull()
    .default("00000000-0000-0000-0000-000000000000"),
  branchId: uuid("branch_id"),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  userAccountName: varchar("user_account_name", { length: 255 }),
  systemAccountName: varchar("system_account_name", { length: 255 }),
  accountType: varchar("account_type", { length: 50 }).notNull(),
  accountGroup: varchar("account_group", { length: 50 }),
  accountCode: varchar("account_code", { length: 50 }),
  accountNumber: varchar("account_number", { length: 100 }),
  ifsc: varchar("ifsc", { length: 50 }),
  description: text("description"),
  currency: varchar("currency", { length: 10 }).default("INR"),
  parentId: uuid("parent_id").references(() => account.id),
  showInZerpaiExpense: boolean("show_in_zerpai_expense").default(false),
  addToWatchlist: boolean("add_to_watchlist").default(false),
  isSystem: boolean("is_system").default(false),
  isDeletable: boolean("is_deletable").default(true),
  isActive: boolean("is_active").default(true),
  isDeleted: boolean("is_deleted").default(false),
  createdBy: uuid("created_by"),
  createdAt: timestamp("created_at").defaultNow(),
  modifiedBy: uuid("modified_by"),
  modifiedAt: timestamp("modified_at").defaultNow(),
});

// Account Transaction Table
export const accountTransaction = pgTable("account_transactions", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  accountId: uuid("account_id")
    .notNull()
    .references(() => account.id, { onDelete: "cascade" }),
  transactionDate: timestamp("transaction_date").notNull(),
  transactionType: varchar("transaction_type", { length: 50 }),
  referenceNumber: varchar("reference_number", { length: 100 }),
  description: text("description"),
  debit: decimal("debit", { precision: 15, scale: 2 }).default("0.00"),
  credit: decimal("credit", { precision: 15, scale: 2 }).default("0.00"),
  sourceId: uuid("source_id"),
  sourceType: varchar("source_type", { length: 50 }),
  contactId: uuid("contact_id"),
  contactType: varchar("contact_type", { length: 50 }),
  createdAt: timestamp("created_at").defaultNow(),
});


// Storage Location Table
export const storageLocation = pgTable("storage_location", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id").notNull().references(() => organisationBranchMaster.id),
  locationName: varchar("location_name", { length: 255 }).notNull(),
  description: text("description"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
});

// Rack Table
export const rack = pgTable("rack_master", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id").notNull().references(() => organisationBranchMaster.id),
  warehouseId: uuid("warehouse_id").notNull().references(() => warehouses.id),
  rackName: varchar("rack_name", { length: 255 }).notNull(),
  rackCode: varchar("rack_code", { length: 50 }),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
});

// Bin Table
export const bin = pgTable("bin_master", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id").notNull().references(() => organisationBranchMaster.id),
  warehouseId: uuid("warehouse_id").notNull().references(() => warehouses.id),
  rackId: uuid("rack_id").notNull().references(() => rack.id),
  binCode: varchar("bin_code", { length: 255 }).notNull(),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
});

// Batch Stock Layers Table
export const batchStockLayers = pgTable("batch_stock_layers", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id").notNull().references(() => organisationBranchMaster.id),
  warehouseId: uuid("warehouse_id").notNull().references(() => warehouses.id),
  binId: uuid("bin_id").references(() => bin.id),
  productId: uuid("product_id").notNull().references(() => product.id),
  batchId: uuid("batch_id").notNull().references(() => batches.id),
  qty: numeric("qty", { precision: 15, scale: 3 }).default("0"),
  purchaseRate: numeric("purchase_rate", { precision: 15, scale: 2 }).default("0"),
  mrp: numeric("mrp", { precision: 15, scale: 2 }).default("0"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
});

// Reorder Term Table
export const reorderTerm = pgTable("reorder_terms", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  termName: varchar("term_name", { length: 255 }).notNull(),
  quantity: integer("quantity").notNull().default(1),
  description: text("description"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Payment Terms Table
export const paymentTerms = pgTable("payment_terms", {
  id: uuid("id").primaryKey().defaultRandom(),
  termName: varchar("term_name", { length: 255 }).notNull().unique(),
  numberOfDays: integer("number_of_days").notNull(),
  description: text("description"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Vendor Table
export const vendor = pgTable("vendors", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: uuid("org_id")
    .notNull()
    .default("00000000-0000-0000-0000-000000000000"),
  branchId: uuid("branch_id").references(() => settingsBranches.id),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  vendorNumber: varchar("vendor_number", { length: 255 }).unique(),
  displayName: varchar("display_name", { length: 255 }).notNull(),
  salutation: varchar("salutation", { length: 255 }),
  firstName: varchar("first_name", { length: 255 }),
  lastName: varchar("last_name", { length: 255 }),
  companyName: varchar("company_name", { length: 255 }),
  email: varchar("email", { length: 255 }),
  phone: varchar("phone", { length: 50 }),
  mobilePhone: varchar("mobile_phone", { length: 50 }),
  designation: varchar("designation", { length: 255 }),
  department: varchar("department", { length: 255 }),
  website: varchar("website", { length: 255 }),
  vendorLanguage: varchar("vendor_language", { length: 255 }).default(
    "English",
  ),
  gstTreatment: varchar("gst_treatment", { length: 100 }),
  gstin: varchar("gstin", { length: 50 }),
  sourceOfSupply: varchar("source_of_supply", { length: 255 }),
  pan: varchar("pan", { length: 50 }),
  currency: varchar("currency", { length: 20 }).default("INR"),
  paymentTerms: varchar("payment_terms", { length: 255 }),
  isMsmeRegistered: boolean("is_msme_registered").default(false),
  msmeRegistrationType: varchar("msme_registration_type", { length: 255 }),
  msmeRegistrationNumber: varchar("msme_registration_number", { length: 255 }),
  isDrugRegistered: boolean("is_drug_registered").default(false),
  drugLicenceType: varchar("drug_licence_type", { length: 255 }),
  drugLicense20: varchar("drug_license_20", { length: 255 }),
  drugLicense21: varchar("drug_license_21", { length: 255 }),
  drugLicense20b: varchar("drug_license_20b", { length: 255 }),
  drugLicense21b: varchar("drug_license_21b", { length: 255 }),
  isFssaiRegistered: boolean("is_fssai_registered").default(false),
  fssaiNumber: varchar("fssai_number", { length: 255 }),
  tdsRateId: varchar("tds_rate_id", { length: 255 }),
  priceListId: uuid("price_list_id"),
  enablePortal: boolean("enable_portal").default(false),
  remarks: text("remarks"),
  xHandle: varchar("x_handle", { length: 255 }),
  facebookHandle: varchar("facebook_handle", { length: 255 }),
  whatsappNumber: varchar("whatsapp_number", { length: 50 }),
  source: varchar("source", { length: 255 }).default("User"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),

  // Addresses
  billingAttention: text("billing_attention"),
  billingAddressStreet: text("billing_address_street"),
  billingAddressPlace: text("billing_address_place"),
  billingCity: text("billing_city"),
  billingState: text("billing_state"),
  billingPincode: text("billing_pincode"),
  billingCountryRegion: text("billing_country_region"),
  billingPhone: text("billing_phone"),

  shippingAttention: text("shipping_attention"),
  shippingAddressStreet: text("shipping_address_street"),
  shippingAddressPlace: text("shipping_address_place"),
  shippingCity: text("shipping_city"),
  shippingState: text("shipping_state"),
  shippingPincode: text("shipping_pincode"),
  shippingCountryRegion: text("shipping_country_region"),
  shippingPhone: text("shipping_phone"),
});

// Vendor Bank Account Table
export const vendorBankAccount = pgTable("vendor_bank_accounts", {
  id: uuid("id").primaryKey().defaultRandom(),
  vendorId: uuid("vendor_id").references(() => vendor.id),
  holderName: text("holder_name"),
  bankName: text("bank_name"),
  accountNumber: text("account_number"),
  ifsc: text("ifsc"),
  isPrimary: boolean("is_primary").default(false),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
});

// Vendor Contact Person Table
export const vendorContactPerson = pgTable("vendor_contact_persons", {
  id: uuid("id").primaryKey().defaultRandom(),
  vendorId: uuid("vendor_id").references(() => vendor.id),
  salutation: text("salutation"),
  firstName: text("first_name"),
  lastName: text("last_name"),
  email: text("email"),
  workPhone: text("work_phone"),
  mobilePhone: text("mobile_phone"),
  designation: text("designation"),
  department: text("department"),
  isPrimary: boolean("is_primary").default(false),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow(),
});

// Price List Table
export const priceList = pgTable("price_lists", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull(),
  description: text("description"),
  currency: varchar("currency", { length: 20 }).default("INR"),
  transactionType: varchar("transaction_type", { length: 20 }).default("Sales"), // 'Sales', 'Purchase'
  priceListType: varchar("price_list_type", { length: 50 }).default(
    "all_items",
  ), // 'all_items', 'individual_items'
  pricingScheme: varchar("pricing_scheme", { length: 50 }).notNull(), // 'unit_pricing', 'volume_pricing'
  percentageType: varchar("percentage_type", { length: 20 }), // 'Markup', 'Markdown' (for all_items)
  percentageValue: decimal("percentage_value", { precision: 5, scale: 2 }), // Percentage value (for all_items)
  roundOffPreference: varchar("round_off_preference", { length: 50 }).default(
    "never_mind",
  ),
  discountEnabled: boolean("discount_enabled").default(false),
  details: text("details"),
  status: varchar("status", { length: 20 }).default("active"),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Price List Items Table (for individual_items type)
export const priceListItem = pgTable("price_list_items", {
  id: uuid("id").primaryKey().defaultRandom(),
  priceListId: uuid("price_list_id")
    .notNull()
    .references(() => priceList.id, { onDelete: "cascade" }),
  productId: uuid("product_id")
    .notNull()
    .references(() => product.id, { onDelete: "cascade" }),
  customRate: decimal("custom_rate", { precision: 15, scale: 2 }), // Custom rate for unit pricing
  discountPercentage: decimal("discount_percentage", {
    precision: 5,
    scale: 2,
  }), // Discount if enabled
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Price List Volume Ranges Table (for volume_pricing scheme)
export const priceListVolumeRange = pgTable("price_list_volume_ranges", {
  id: uuid("id").primaryKey().defaultRandom(),
  priceListItemId: uuid("price_list_item_id")
    .notNull()
    .references(() => priceListItem.id, { onDelete: "cascade" }),
  startQuantity: decimal("start_quantity", {
    precision: 15,
    scale: 2,
  }).notNull(),
  endQuantity: decimal("end_quantity", { precision: 15, scale: 2 }), // NULL = no upper limit
  rate: decimal("rate", { precision: 15, scale: 2 }).notNull(),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Lookup Table: Content Units
export const contentUnits = pgTable("content_unit", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 50 }).notNull().unique(),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Lookup Table: Contents
export const contents = pgTable("contents", {
  id: uuid("id").primaryKey().defaultRandom(),
  contentName: varchar("content_name", { length: 255 }).notNull().unique(),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Lookup Table: Strengths
export const strengths = pgTable("drug_strengths", {
  id: uuid("id").primaryKey().defaultRandom(),
  strengthName: varchar("strength_name", { length: 100 }).notNull().unique(),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Lookup Table: Buying Rules
export const buyingRules = pgTable("buying_rules", {
  id: uuid("id").primaryKey().defaultRandom(),
  itemRule: varchar("item_rule", { length: 255 }).notNull().unique(),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Lookup Table: Schedules
export const schedule = pgTable("drug_schedules", {
  id: uuid("id").primaryKey().defaultRandom(),
  sheduleName: varchar("shedule_name", { length: 100 }).notNull().unique(),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Product Table
export const product = pgTable("products", {
  id: uuid("id").primaryKey().defaultRandom(),

  // Basic Information
  type: productTypeEnum("type").notNull(),
  productName: varchar("product_name", { length: 255 }).notNull(),
  billingName: varchar("billing_name", { length: 255 }),
  itemCode: varchar("item_code", { length: 100 }).notNull().unique(),
  sku: varchar("sku", { length: 100 }).unique(),
  unitId: uuid("unit_id")
    .notNull()
    .references(() => unit.id),
  categoryId: uuid("category_id").references(() => category.id),
  isReturnable: boolean("is_returnable").default(false),
  pushToEcommerce: boolean("push_to_ecommerce").default(false),

  // Tax & Regulatory
  hsnCode: varchar("hsn_code", { length: 50 }),
  taxPreference: taxPreferenceEnum("tax_preference"),
  intraStateTaxId: uuid("intra_state_tax_id").references(() => taxRate.id),
  interStateTaxId: uuid("inter_state_tax_id").references(() => taxRate.id),
  exemptionReason: varchar("exemption_reason", { length: 255 }),

  // Images
  primaryImageUrl: text("primary_image_url"),
  imageUrls: jsonb("image_urls"),

  // Sales Information
  sellingPrice: decimal("selling_price", { precision: 15, scale: 2 }),
  sellingPriceCurrency: varchar("selling_price_currency", {
    length: 10,
  }).default("INR"),
  mrp: decimal("mrp", { precision: 15, scale: 2 }),
  ptr: decimal("ptr", { precision: 15, scale: 2 }),
  salesAccountId: uuid("sales_account_id").references(() => account.id),
  salesDescription: text("sales_description"),

  // Purchase Information
  costPrice: decimal("cost_price", { precision: 15, scale: 2 }),
  costPriceCurrency: varchar("cost_price_currency", { length: 10 }).default(
    "INR",
  ),
  purchaseAccountId: uuid("purchase_account_id").references(() => account.id),
  preferredVendorId: uuid("preferred_vendor_id").references(() => vendor.id),
  purchaseDescription: text("purchase_description"),

  // Formulation
  length: decimal("length", { precision: 10, scale: 2 }),
  width: decimal("width", { precision: 10, scale: 2 }),
  height: decimal("height", { precision: 10, scale: 2 }),
  dimensionUnit: varchar("dimension_unit", { length: 10 }).default("cm"),
  weight: decimal("weight", { precision: 10, scale: 2 }),
  weightUnit: varchar("weight_unit", { length: 10 }).default("kg"),
  manufacturerId: uuid("manufacturer_id").references(() => manufacturer.id),
  brandId: uuid("brand_id").references(() => brand.id),
  mpn: varchar("mpn", { length: 100 }),
  upc: varchar("upc", { length: 20 }),
  isbn: varchar("isbn", { length: 20 }),
  ean: varchar("ean", { length: 20 }),

  // Composition
  trackAssocIngredients: boolean("track_assoc_ingredients").default(false),
  buyingRuleId: uuid("buying_rule_id").references(() => buyingRules.id),
  scheduleOfDrugId: uuid("schedule_of_drug_id").references(() => schedule.id),
  trackSerialNumber: boolean("track_serial_number").default(false),

  // Inventory Settings
  isTrackInventory: boolean("is_track_inventory").default(true),
  trackBinLocation: boolean("track_bin_location").default(false),
  trackBatches: boolean("track_batches").default(false),
  inventoryAccountId: uuid("inventory_account_id").references(() => account.id),
  inventoryValuationMethod: inventoryValuationMethodEnum(
    "inventory_valuation_method",
  ),
  storageId: uuid("storage_id").references(() => storageLocation.id),
  rackId: uuid("rack_id").references(() => rack.id),
  reorderPoint: integer("reorder_point").default(0),
  reorderTermId: uuid("reorder_term_id").references(() => reorderTerm.id),
  lockUnitPack: integer("lock_unit_pack").default(1),

  // eCommerce Information
  storageDescription: text("storage_description"),
  about: text("about"),
  usesDescription: text("uses_description"),
  howToUse: text("how_to_use"),
  dosageDescription: text("dosage_description"),
  missedDoseDescription: text("missed_dose_description"),
  safetyAdvice: text("safety_advice"),
  sideEffects: jsonb("side_effects"), // Array of strings
  faqText: jsonb("faq_text"), // Array of strings

  // Status Flags
  isActive: boolean("is_active").default(true),
  isLock: boolean("is_lock").default(false),

  // System Fields (no auth references for development)
  createdAt: timestamp("created_at").defaultNow(),
  createdById: uuid("created_by_id"),
  updatedAt: timestamp("updated_at").defaultNow(),
  updatedById: uuid("updated_by_id"),
});

// Product Content (Salt/Composition) Table
export const productContent = pgTable("product_contents", {
  id: uuid("id").primaryKey().defaultRandom(),
  productId: uuid("product_id")
    .notNull()
    .references(() => product.id, { onDelete: "cascade" }),
  contentId: uuid("content_id").references(() => contents.id),
  strengthId: uuid("strength_id").references(() => strengths.id),
  contentUnitId: uuid("content_unit_id").references(() => contentUnits.id),
  sheduleId: uuid("shedule_id").references(() => schedule.id), // Retaining 'shedule' typo for DB compatibility
  displayOrder: integer("display_order").default(0),
  createdAt: timestamp("created_at").defaultNow(),
});

// Product Parts Table (for Composite Items)
export const productParts = pgTable("product_parts", {
  id: uuid("id").primaryKey().defaultRandom(),
  productId: uuid("product_id")
    .notNull()
    .references(() => product.id, { onDelete: "cascade" }),
  componentProductId: uuid("component_product_id")
    .notNull()
    .references(() => product.id),
  quantity: decimal("quantity", { precision: 15, scale: 2 }).notNull(),
  sellingPriceOverride: decimal("selling_price_override", {
    precision: 15,
    scale: 2,
  }),
  costPriceOverride: decimal("cost_price_override", {
    precision: 15,
    scale: 2,
  }),
  createdAt: timestamp("created_at").defaultNow(),
});

// =====================================
// SALES MODULE
// =====================================

// Customer Table
export const customer = pgTable("customers", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id").notNull().references(() => organisationBranchMaster.id),
  customerNumber: varchar("customer_number", { length: 100 }).unique(),
  displayName: varchar("display_name", { length: 255 }).notNull(),
  customerType: varchar("customer_type", { length: 50 }).default("Business"),
  salutation: varchar("salutation", { length: 255 }),
  firstName: varchar("first_name", { length: 255 }),
  lastName: varchar("last_name", { length: 255 }),
  companyName: varchar("company_name", { length: 255 }),
  businessType: varchar("business_type", { length: 255 }),
  email: varchar("email", { length: 255 }),
  phone: varchar("phone", { length: 50 }),
  mobilePhone: varchar("mobile_phone", { length: 50 }),
  designation: varchar("designation", { length: 255 }),
  department: varchar("department", { length: 255 }),
  website: varchar("website", { length: 255 }),
  customerLanguage: varchar("customer_language", { length: 255 }).default(
    "English",
  ),

  // Personal Info
  dateOfBirth: timestamp("date_of_birth"),
  age: integer("age"),
  gender: varchar("gender", { length: 50 }),

  // Tax & Regulatory
  gstTreatment: varchar("gst_treatment", { length: 100 }),
  gstin: varchar("gstin", { length: 50 }),
  placeOfSupply: varchar("place_of_supply", { length: 100 }),
  pan: varchar("pan", { length: 50 }),
  taxPreference: varchar("tax_preference", { length: 50 }).default("Taxable"),
  exemptionReason: text("exemption_reason"),

  // License Details
  isDrugRegistered: boolean("Is_drug_registered"),
  drugLicenceType: varchar("drug_licence_type", { length: 255 }),
  drugLicense20: varchar("drug_license_20", { length: 255 }),
  drugLicense21: varchar("drug_license_21", { length: 255 }),
  drugLicense20b: varchar("drug_license_20b", { length: 255 }),
  drugLicense21b: varchar("drug_license_21b", { length: 255 }),
  drugLicense20DocUrl: text("drug_license_20_doc_url"),
  drugLicense21DocUrl: text("drug_license_21_doc_url"),
  drugLicense20bDocUrl: text("drug_license_20b_doc_url"),
  drugLicense21bDocUrl: text("drug_license_21b_doc_url"),

  isFssaiRegistered: boolean("Is_fssai_registered"),
  fssaiNumber: varchar("fssai", { length: 255 }),
  fssaiDocUrl: text("fssai_doc_url"),

  isMsmeRegistered: boolean("Is_msme_registered"),
  msmeRegistrationType: varchar("msme_registration_type", { length: 255 }),
  msmeNumber: varchar("msme_number", { length: 255 }),
  msmeDocUrl: text("msme_doc_url"),

  // Finance Details
  currency: varchar("currency", { length: 20 }).default("INR"),
  openingBalance: decimal("opening_balance", {
    precision: 15, scale: 2,
  }).default("0.00"),
  creditLimit: decimal("credit_limit", { precision: 15, scale: 2 }).default(
    "0.00",
  ),
  paymentTerms: varchar("payment_terms", { length: 100 }),
  priceList: varchar("price_list", { length: 100 }),
  receivables: decimal("receivables", { precision: 15, scale: 2 }).default(
    "0.00",
  ),
  receivableBalance: decimal("receivable_balance", {
    precision: 15, scale: 2,
  }).default("0.00"),

  // Addresses
  billingAddressStreet: varchar("billing_address_street", { length: 255 }),
  billingAddressPlace: varchar("billing_address_place", { length: 255 }),
  billingAddressCity: varchar("billing_address_city", { length: 255 }),
  billingAddressState: varchar("billing_address_state", { length: 255 }),
  billingAddressZip: varchar("billing_address_zip", { length: 20 }),
  billingAddressCountry: varchar("billing_address_country", { length: 255 }),
  billingAddressPhone: varchar("billing_address_phone", { length: 50 }),

  shippingAddressStreet: varchar("shipping_address_street", { length: 255 }),
  shippingAddressPlace: varchar("shipping_address_place", { length: 255 }),
  shippingAddressCity: varchar("shipping_address_city", { length: 255 }),
  shippingAddressState: varchar("shipping_address_state", { length: 255 }),
  shippingAddressZip: varchar("shipping_address_zip", { length: 20 }),
  shippingAddressCountry: varchar("shipping_address_country", { length: 255 }),
  shippingAddressPhone: varchar("shipping_address_phone", { length: 50 }),

  // CRM & Social
  placeOfCustomer: varchar("place_of_customer", { length: 255 }),
  privilegeCardNumber: varchar("privilege_card_number", { length: 255 }),
  enablePortal: boolean("enable_portal").default(false),
  facebookHandle: varchar("facebook_handle", { length: 255 }),
  twitterHandle: varchar("twitter_handle", { length: 255 }),
  whatsappNumber: varchar("whatsapp_number", { length: 50 }),
  isRecurring: boolean("is_recurring").default(false),
  remarks: text("remarks"),
  status: varchar("status", { length: 50 }).default("active"),
  documentUrls: text("document_urls"),

  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Customer Contact Person Table
export const customerContact = pgTable("customer_contact_persons", {
  id: uuid("id").primaryKey().defaultRandom(),
  customerId: uuid("customer_id")
    .notNull()
    .references(() => customer.id, { onDelete: "cascade" }),
  salutation: varchar("salutation", { length: 255 }),
  firstName: varchar("first_name", { length: 255 }),
  lastName: varchar("last_name", { length: 255 }),
  email: varchar("email", { length: 255 }),
  workPhone: varchar("work_phone", { length: 50 }),
  mobilePhone: varchar("mobile_phone", { length: 50 }),
  displayOrder: integer("display_order").default(0),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Sales Order Table
export const salesOrder = pgTable("sales_orders", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  customerId: uuid("customer_id")
    .notNull()
    .references(() => customer.id),
  transactionSeries: varchar("transaction_series"),
  saleNumber: varchar("sale_number").unique(),
  reference: varchar("reference"),
  saleDate: timestamp("sale_date").defaultNow(),
  expectedShipmentDate: timestamp("expected_shipment_date"),
  deliveryMethod: varchar("delivery_method"),
  paymentTerms: varchar("payment_terms"),
  paymentTermId: uuid("payment_term_id").references(() => paymentTerms.id),
  salespersonId: varchar("salesperson_id"),
  salespersonName: varchar("salesperson_name"),
  warehouseId: uuid("warehouse_id").references(() => warehouses.id),
  warehouseName: varchar("warehouse_name"),
  priceListId: uuid("price_list_id").references(() => priceList.id),
  placeOfSupply: varchar("place_of_supply"),
  documentType: varchar("document_type", { length: 50 }).notNull(), // 'quote', 'order', 'invoice', etc.
  status: varchar("status", { length: 50 }).default("Draft"),
  subTotal: numeric("sub_total").notNull().default("0.00"),
  taxTotal: numeric("tax_total").notNull().default("0.00"),
  discountTotal: numeric("discount_total").notNull().default("0.00"),
  shippingCharges: numeric("shipping_charges").notNull().default("0.00"),
  tdsTcsType: varchar("tds_tcs_type").default("TDS"),
  tdsTcsTaxId: uuid("tds_tcs_tax_id").references(() => tdsRate.id),
  tdsTcsAmount: numeric("tds_tcs_amount").notNull().default("0.00"),
  adjustment: numeric("adjustment").notNull().default("0.00"),
  roundOff: numeric("round_off").notNull().default("0.00"),
  totalQuantity: numeric("total_quantity").notNull().default("0.000"),
  total: numeric("total").notNull().default("0.00"),
  currency: varchar("currency", { length: 20 }).default("INR"),
  customerNotes: text("customer_notes"),
  termsAndConditions: text("terms_and_conditions"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const salesOrderItems = pgTable("sales_order_items", {
  id: uuid("id").primaryKey().defaultRandom(),
  salesOrderId: uuid("sales_order_id")
    .notNull()
    .references(() => salesOrder.id),
  lineNo: integer("line_no").notNull().default(1),
  productId: uuid("product_id")
    .notNull()
    .references(() => product.id),
  description: text("description"),
  quantity: numeric("quantity").notNull().default("0.000"),
  freeQuantity: numeric("free_quantity").notNull().default("0.000"),
  rate: numeric("rate").notNull().default("0.00"),
  discountType: varchar("discount_type").default("%"),
  discountValue: numeric("discount_value").notNull().default("0.00"),
  discountAmount: numeric("discount_amount").notNull().default("0.00"),
  taxId: uuid("tax_id").references(() => taxRate.id),
  taxRate: numeric("tax_rate").notNull().default("0.0000"),
  taxAmount: numeric("tax_amount").notNull().default("0.00"),
  amount: numeric("amount").notNull().default("0.00"),
  mrp: numeric("mrp").notNull().default("0.00"),
  batchId: uuid("batch_id").references(() => batches.id),
  warehouseId: uuid("warehouse_id").references(() => warehouses.id),
  lineMeta: jsonb("line_meta"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
});

export const salesOrderAttachments = pgTable("sales_order_attachments", {
  id: uuid("id").primaryKey().defaultRandom(),
  salesOrderId: uuid("sales_order_id")
    .notNull()
    .references(() => salesOrder.id),
  fileName: varchar("file_name").notNull(),
  filePath: text("file_path").notNull(),
  fileSize: integer("file_size"),
  fileType: varchar("file_type"),
  uploadedAt: timestamp("uploaded_at").defaultNow(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
});


// Sales Payment Table
export const salesPayment = pgTable("sales_payments", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id").notNull().references(() => organisationBranchMaster.id),
  customerId: uuid("customer_id")
    .notNull()
    .references(() => customer.id),
  paymentNumber: varchar("payment_number", { length: 100 }).unique(),
  paymentDate: timestamp("payment_date").defaultNow(),
  paymentMode: varchar("payment_mode", { length: 50 }),
  amount: decimal("amount", { precision: 15, scale: 2 }).notNull(),
  bankCharges: decimal("bank_charges", { precision: 15, scale: 2 }).default(
    "0.00",
  ),
  reference: varchar("reference", { length: 100 }),
  depositTo: varchar("deposit_to", { length: 100 }),
  notes: text("notes"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Sales E-Way Bill Table
export const salesEWayBill = pgTable("sales_eway_bills", {
  id: uuid("id").primaryKey().defaultRandom(),
  saleId: uuid("sale_id").references(() => salesOrder.id),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  billNumber: varchar("bill_number", { length: 100 }).unique(),
  billDate: timestamp("bill_date").defaultNow(),
  supplyType: varchar("supply_type", { length: 50 }).default("Outward"),
  subType: varchar("sub_type", { length: 50 }).default("Supply"),
  transporterId: varchar("transporter_id", { length: 100 }),
  vehicleNumber: varchar("vehicle_number", { length: 50 }),
  status: varchar("status", { length: 50 }).default("active"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Sales Payment Link Table
export const salesPaymentLink = pgTable("sales_payment_links", {
  id: uuid("id").primaryKey().defaultRandom(),
  customerId: uuid("customer_id")
    .notNull()
    .references(() => customer.id),
  amount: decimal("amount", { precision: 15, scale: 2 }).notNull(),
  linkUrl: text("link_url").notNull(),
  status: varchar("status", { length: 50 }).default("active"),
  createdAt: timestamp("created_at").defaultNow(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
});

// =====================================
// PURCHASE MODULE
// =====================================

export const purchaseOrders = pgTable("purchase_orders", {
  id: uuid("id").primaryKey().defaultRandom(),
  vendorId: uuid("vendor_id")
    .notNull()
    .references(() => vendor.id),
  transactionSeries: varchar("transaction_series"),
  purchaseNumber: varchar("purchase_number").unique(),
  reference: varchar("reference"),
  purchaseDate: timestamp("purchase_date").defaultNow(),
  expectedDeliveryDate: timestamp("expected_delivery_date"),
  paymentTerms: varchar("payment_terms"),
  paymentTermId: uuid("payment_term_id").references(() => paymentTerms.id),
  warehouseId: uuid("warehouse_id").references(() => warehouses.id),
  warehouseName: varchar("warehouse_name"),
  priceListId: uuid("price_list_id").references(() => priceList.id),
  placeOfSupply: varchar("place_of_supply"),
  documentType: varchar("document_type", { length: 50 }).notNull(),
  status: varchar("status", { length: 50 }).default("Draft"),
  subTotal: numeric("sub_total").notNull().default("0.00"),
  taxTotal: numeric("tax_total").notNull().default("0.00"),
  discountTotal: numeric("discount_total").notNull().default("0.00"),
  tdsTcsType: varchar("tds_tcs_type").default("TDS"),
  tdsTcsTaxId: uuid("tds_tcs_tax_id").references(() => tdsRate.id),
  tdsTcsAmount: numeric("tds_tcs_amount").notNull().default("0.00"),
  adjustment: numeric("adjustment").notNull().default("0.00"),
  roundOff: numeric("round_off").notNull().default("0.00"),
  totalQuantity: numeric("total_quantity").notNull().default("0.000"),
  total: numeric("total").notNull().default("0.00"),
  currency: varchar("currency", { length: 20 }).default("INR"),
  vendorNotes: text("vendor_notes"),
  termsAndConditions: text("terms_and_conditions"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
});

export const purchaseOrderItems = pgTable("purchase_order_items", {
  id: uuid("id").primaryKey().defaultRandom(),
  purchaseOrderId: uuid("purchase_order_id")
    .notNull()
    .references(() => purchaseOrders.id, { onDelete: "cascade" }),
  sortOrder: integer("sort_order"),
  isHeader: boolean("is_header").default(false),
  headerText: text("header_text"),
  productId: uuid("product_id").references(() => product.id),
  description: text("description"),
  accountId: uuid("account_id").references(() => account.id),
  quantity: numeric("quantity").default("0.00"),
  rate: numeric("rate").default("0.00"),
  taxId: uuid("tax_id").references(() => taxRate.id),
  itemTaxRate: numeric("item_tax_rate").default("0.00"),
  taxAmount: numeric("tax_amount").default("0.00"),
  discount: numeric("discount").default("0.00"),
  discountType: varchar("discount_type").default("percentage"),
  amount: numeric("amount").default("0.00"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
});

export const purchaseOrderAttachments = pgTable("purchase_order_attachments", {
  id: uuid("id").primaryKey().defaultRandom(),
  purchaseOrderId: uuid("purchase_order_id")
    .notNull()
    .references(() => purchaseOrders.id, { onDelete: "cascade" }),
  fileName: varchar("file_name").notNull(),
  filePath: text("file_path").notNull(),
  fileSize: integer("file_size"),
  fileType: varchar("file_type"),
  uploadedAt: timestamp("uploaded_at").defaultNow(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
});

export const purchaseReceives = pgTable("purchase_receives", {
  id: uuid("id").primaryKey().defaultRandom(),
  purchaseReceiveNumber: varchar("purchase_receive_number").notNull(),
  receivedDate: date("received_date").notNull(),
  vendorName: varchar("vendor_name"),
  purchaseOrderId: uuid("purchase_order_id").references(() => purchaseOrders.id),
  purchaseOrderNumber: varchar("purchase_order_number"),
  warehouseId: uuid("warehouse_id").references(() => warehouses.id),
  transactionBinId: uuid("transaction_bin_id"),
  transactionBinLabel: varchar("transaction_bin_label"),
  status: varchar("status", { length: 50 }).notNull().default("draft"),
  notes: text("notes"),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const purchaseReceiveItems = pgTable("purchase_receive_items", {
  id: uuid("id").primaryKey().defaultRandom(),
  purchaseReceiveId: uuid("purchase_receive_id")
    .notNull()
    .references(() => purchaseReceives.id, { onDelete: "cascade" }),
  itemId: uuid("item_id").references(() => product.id),
  itemName: varchar("item_name").notNull(),
  description: text("description"),
  ordered: numeric("ordered").notNull().default("0"),
  received: numeric("received").notNull().default("0"),
  inTransit: numeric("in_transit").notNull().default("0"),
  quantityToReceive: numeric("quantity_to_receive").notNull().default("0"),
  warehouseId: uuid("warehouse_id").references(() => warehouses.id),
  binId: uuid("bin_id"),
  binLabel: varchar("bin_label"),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const purchaseReceiveItemBatches = pgTable("purchase_receive_item_batches", {
  id: uuid("id").primaryKey().defaultRandom(),
  purchaseReceiveItemId: uuid("purchase_receive_item_id")
    .notNull()
    .references(() => purchaseReceiveItems.id, { onDelete: "cascade" }),
  productId: uuid("product_id")
    .notNull()
    .references(() => product.id),
  warehouseId: uuid("warehouse_id").references(() => warehouses.id),
  binId: uuid("bin_id"),
  batchNo: varchar("batch_no").notNull(),
  unitPack: varchar("unit_pack"),
  mrp: numeric("mrp"),
  ptr: numeric("ptr"),
  quantity: numeric("quantity").notNull().default("0"),
  focQty: numeric("foc_qty").notNull().default("0"),
  manufactureBatchNumber: varchar("manufacture_batch_number"),
  manufactureDate: date("manufacture_date"),
  expiryDate: date("expiry_date").notNull(),
  isDamaged: boolean("is_damaged").notNull().default(false),
  damagedQty: numeric("damaged_qty").notNull().default("0"),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});


// Organization Table (Multi-tenancy Master)
// Branch Inventory Table
export const branchInventory = pgTable(
  "branch_inventory",
  {
    id: uuid().defaultRandom().primaryKey().notNull(),
    entityId: uuid("entity_id").notNull().references(() => organisationBranchMaster.id),
    productId: uuid("product_id").notNull(),
    currentStock: integer("current_stock").default(0).notNull(),
    reservedStock: integer("reserved_stock").default(0),
    availableStock: integer("available_stock").generatedAlwaysAs(
      sql`(current_stock - reserved_stock)`,
    ),
    batchNo: varchar("batch_no", { length: 100 }),
    expiryDate: date("expiry_date"),
    minStockLevel: integer("min_stock_level").default(0),
    maxStockLevel: integer("max_stock_level").default(0),
    lastStockUpdate: timestamp("last_stock_update", {
      withTimezone: true,
      mode: "string",
    }).defaultNow(),
    createdAt: timestamp("created_at", { withTimezone: true, mode: "string" }).defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true, mode: "string" }).defaultNow(),
  },
  (table) => [
    index("idx_branch_inventory_expiry").using(
      "btree",
      table.expiryDate.asc().nullsLast().op("date_ops"),
    ),
    index("idx_branch_inventory_entity").using(
      "btree",
      table.entityId.asc().nullsLast().op("uuid_ops"),
    ),
    index("idx_branch_inventory_entity_product").using(
      "btree",
      table.entityId.asc().nullsLast().op("uuid_ops"),
      table.productId.asc().nullsLast().op("uuid_ops"),
    ),
    index("idx_branch_inventory_product").using(
      "btree",
      table.productId.asc().nullsLast().op("uuid_ops"),
    ),
    unique("branch_inventory_entity_id_product_id_batch_no_key").on(
      table.entityId,
      table.productId,
      table.batchNo,
    ),
    check("branch_inventory_current_stock_check", sql`current_stock >= 0`),
  ],
);

export const productBranchInventorySettings = pgTable(
  "product_branch_inventory_settings",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    entityId: uuid("entity_id").notNull().references(() => organisationBranchMaster.id),
    productId: uuid("product_id")
      .notNull()
      .references(() => product.id, { onDelete: "cascade" }),
    reorderPoint: integer("reorder_point").notNull().default(0),
    reorderTermId: uuid("reorder_term_id").references(() => reorderTerm.id, {
      onDelete: "set null",
    }),
    isActive: boolean("is_active").notNull().default(true),
    createdById: uuid("created_by_id"),
    updatedById: uuid("updated_by_id"),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
);

// LSGD Hierarchy Masters
export const settingsDistricts = pgTable("lsgd_districts", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull(),
  stateId: uuid("state_id").notNull(),
});

export const settingsLocalBodies = pgTable("lsgd_local_bodies", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull(),
  districtId: uuid("district_id").notNull().references(() => settingsDistricts.id),
  bodyType: varchar("body_type", { length: 50 }),
});

export const settingsAssemblies = pgTable("assemblies_constituencies", {
  id: uuid("id").primaryKey().defaultRandom(),
  districtId: uuid("district_id")
    .notNull()
    .references(() => settingsDistricts.id),
  name: varchar("name", { length: 150 }).notNull(),
  code: varchar("code", { length: 50 }),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const settingsWards = pgTable("lsgd_wards", {
  id: uuid("id").primaryKey().defaultRandom(),
  wardNumber: integer("ward_number").notNull(),
  wardName: varchar("ward_name", { length: 255 }),
  localBodyId: uuid("local_body_id").notNull().references(() => settingsLocalBodies.id),
});

export const settingsLSGDSeedStage = pgTable("settings_lsgd_seed_stage", {
  id: uuid("id").primaryKey().defaultRandom(),
  data: jsonb("data"),
  processed: boolean("processed").default(false),
});

// Unified Branches Table (Replacement for Locations)
export const settingsBranches = pgTable("branches", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: uuid("org_id").notNull().references(() => organizations.id, { onDelete: "cascade" }),
  name: varchar("name", { length: 255 }).notNull(),
  branchCode: varchar("branch_code", { length: 50 }).notNull(),
  systemId: varchar("system_id", { length: 50 }),
  branchType: branchTypeEnum("branch_type").default("FOFO"),
  email: varchar("email", { length: 255 }),
  phone: varchar("phone", { length: 50 }),
  website: varchar("website", { length: 255 }),
  attention: text("attention"),
  street: text("street"),
  place: text("place"),
  city: varchar("city", { length: 100 }),
  state: varchar("state", { length: 100 }),
  country: varchar("country", { length: 100 }).default("India"),
  pincode: varchar("pincode", { length: 20 }),
  districtId: uuid("district_id").references(() => settingsDistricts.id),
  localBodyId: uuid("local_body_id").references(() => settingsLocalBodies.id),
  assemblyId: uuid("assembly_id").references(() => settingsAssemblies.id),
  wardId: uuid("ward_id").references(() => settingsWards.id),
  landmark: text("landmark"),
  isPrimary: boolean("is_primary").notNull().default(false),
  isActive: boolean("is_active").notNull().default(true),

  // Hierarchy & Ownership
  isChildLocation: boolean("is_child_location").default(false),
  parentBranchId: uuid("parent_branch_id"), // Not referencing self yet for simplicity in migrations if circular, but typically allowed
  primaryContactId: uuid("primary_contact_id").references(() => users.id),
  
  // Enterprise & GST
  industry: varchar("industry", { length: 255 }),
  pan: varchar("pan", { length: 10 }),
  gstin: varchar("gstin", { length: 15 }),
  gstTreatment: varchar("gst_treatment", { length: 50 }),
  gstinRegistrationType: varchar("gstin_registration_type", { length: 50 }),
  gstinLegalName: varchar("gstin_legal_name", { length: 255 }),
  gstinTradeName: varchar("gstin_trade_name", { length: 255 }),
  gstinRegisteredOn: date("gstin_registered_on"),
  gstinReverseCharge: boolean("gstin_reverse_charge").default(false),
  gstinImportExport: boolean("gstin_import_export").default(false),
  gstinImportExportAccountId: uuid("gstin_import_export_account_id"),
  gstinDigitalServices: boolean("gstin_digital_services").default(false),

  // Regulatory Compliance
  isDrugRegistered: boolean("is_drug_registered").default(false),
  drugLicenceType: varchar("drug_licence_type", { length: 50 }),
  drugLicence20: varchar("drug_licence_20", { length: 255 }),
  drugLicence21: varchar("drug_licence_21", { length: 255 }),
  drugLicence20b: varchar("drug_licence_20b", { length: 255 }),
  drugLicence21b: varchar("drug_licence_21b", { length: 255 }),
  isFssaiRegistered: boolean("is_fssai_registered").default(false),
  fssaiNumber: varchar("fssai_number", { length: 255 }),
  isMsmeRegistered: boolean("is_msme_registered").default(false),
  msmeRegistrationType: varchar("msme_registration_type", { length: 50 }),
  msmeNumber: varchar("msme_number", { length: 255 }),
  msmeType: varchar("msme_type", { length: 50 }),

  // Settings & Subs
  logoUrl: text("logo_url"),
  subscriptionFrom: date("subscription_from"),
  subscriptionTo: date("subscription_to"),
  defaultTransactionSeriesId: uuid("default_transaction_series_id"),

  // Payment Stub Address (Independent for each branch)
  hasSeparatePaymentStubAddress: boolean("has_separate_payment_stub_address").default(false),
  paymentStubAddress: text("payment_stub_address"),
  paymentStubDistrictId: uuid("payment_stub_district_id").references(() => settingsDistricts.id),
  paymentStubLocalBodyId: uuid("payment_stub_local_body_id").references(() => settingsLocalBodies.id),
  paymentStubWardId: uuid("payment_stub_ward_id").references(() => settingsWards.id),
  paymentStubAssemblyId: uuid("payment_stub_assembly_id").references(() => settingsAssemblies.id),

  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
});


export const settingsTransactionSeries = pgTable("transaction_series", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: uuid("org_id"),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  name: varchar("name", { length: 255 }).notNull(),
  modules: jsonb("modules").notNull().default([]),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
  code: varchar("code", { length: 50 }),
  branchCode: varchar("branch_code", { length: 50 }),
  warehouseCode: varchar("warehouse_code", { length: 50 }),
});
export const settingsBranchTransactionSeries = pgTable("branch_transaction_series", {
  id: uuid("id").primaryKey().defaultRandom(),
  transactionSeriesId: uuid("transaction_series_id")
    .notNull()
    .references(() => settingsTransactionSeries.id),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
});

export const users = pgTable("users", {
  id: uuid("id").primaryKey(),
  email: varchar("email", { length: 255 }).notNull().unique(),
  fullName: varchar("full_name", { length: 255 }).notNull(),
  role: varchar("role", { length: 50 }).notNull().default("user"),
  orgId: uuid("org_id")
    .notNull()
    .references(() => organizations.id),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Transactional Sequences Table
export const transactionalSequence = pgTable("transactional_sequences", {
  id: uuid("id").primaryKey().defaultRandom(),
  module: varchar("module", { length: 50 }).notNull(),
  prefix: varchar("prefix", { length: 20 }).notNull().default(""),
  nextNumber: integer("next_number").notNull().default(1),
  suffix: varchar("suffix", { length: 20 }).notNull().default(""),
  padding: integer("padding").notNull().default(6),
  entityId: uuid("entity_id").notNull().references(() => organisationBranchMaster.id),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Batches Table
export const batches = pgTable("batch_master", {
  id: uuid("id").primaryKey().defaultRandom(),
  productId: uuid("product_id").references(() => product.id, {
    onDelete: "cascade",
  }),
  batchNumber: varchar("batch_no", { length: 100 }).notNull(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  expiryDate: date("expiry_date").notNull(),
  mrp: decimal("mrp", { precision: 15, scale: 2 }).notNull(),
  ptr: decimal("ptr", { precision: 15, scale: 2 }).notNull(),
  unitPack: varchar("unit_pack", { length: 50 }),
  isManufactureDetails: boolean("is_manufacture_details").default(false),
  manufactureBatchNumber: varchar("manufacture_batch_number", { length: 100 }),
  manufactureExpiryDate: date("manufacture_exp"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const batchTransactions = pgTable("batch_transactions", {
  id: uuid("id").primaryKey().defaultRandom(),
  batchId: uuid("batch_id")
    .notNull()
    .references(() => batches.id),
  layerId: uuid("layer_id"),
  productId: uuid("product_id")
    .notNull()
    .references(() => product.id),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  warehouseId: uuid("warehouse_id")
    .notNull()
    .references(() => warehouses.id),
  binId: uuid("bin_id"),
  transType: varchar("trans_type").notNull(),
  refId: uuid("ref_id"),
  refNo: varchar("ref_no"),
  qtyIn: numeric("qty_in").default("0"),
  qtyOut: numeric("qty_out").default("0"),
  rate: numeric("rate"),
  transDate: timestamp("trans_date").notNull().defaultNow(),
  createdAt: timestamp("created_at").defaultNow(),
});


// HSN/SAC Codes Table
export const hsnSacCodes = pgTable(
  "hsn_sac_codes",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    type: hsnSacTypeEnum("type").notNull(),
    code: varchar("code", { length: 15 }).notNull().unique(),
    description: text("description").notNull(),
  },
  (table) => {
    return {
      codeIdx: index("idx_hsn_sac_code").on(table.code),
      typeIdx: index("idx_hsn_sac_type").on(table.type),
    };
  },
);

// Fiscal Years Table
export const accountsFiscalYears = pgTable("fiscal_years", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  name: varchar("name", { length: 100 }).notNull(),
  startDate: date("start_date").notNull(),
  endDate: date("end_date").notNull(),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Manual Journal Tables

export const accountsManualJournals = pgTable("manual_journals", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  journalNumber: varchar("journal_number", { length: 255 }).notNull().unique(),

  fiscalYearId: uuid("fiscal_year_id"),
  referenceNumber: varchar("reference_number", { length: 255 }),
  journalDate: date("journal_date").notNull(),
  notes: text("notes"),
  is13thMonthAdjustment: boolean("is_13th_month_adjustment").default(false),
  reportingMethod: varchar("reporting_method", { length: 50 }).default(
    "accrual_and_cash",
  ),
  currencyCode: varchar("currency_code", { length: 10 }).default("INR"),
  status: varchar("status", { length: 50 }).default("draft"),
  totalAmount: numeric("total_amount", { precision: 15, scale: 2 }).default(
    "0.00",
  ),
  isDeleted: boolean("is_deleted").default(false),
  recurringJournalId: uuid("recurring_journal_id"),
  createdById: uuid("created_by"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const accountsManualJournalItems = pgTable(
  "manual_journal_items",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    manualJournalId: uuid("manual_journal_id")
      .notNull()
      .references(() => accountsManualJournals.id, { onDelete: "cascade" }),
    entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
    accountId: uuid("account_id").notNull(),
    description: text("description"),
    contactId: uuid("contact_id"),
    contactType: varchar("contact_type", { length: 50 }),
    contactName: varchar("contact_name", { length: 255 }),
    debit: numeric("debit", { precision: 15, scale: 2 }).default("0.00"),
    credit: numeric("credit", { precision: 15, scale: 2 }).default("0.00"),
    sortOrder: integer("sort_order").default(0),
    createdAt: timestamp("created_at").defaultNow(),
  },
);

export const accountsManualJournalAttachments = pgTable(
  "manual_journal_attachments",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    manualJournalId: uuid("manual_journal_id")
      .notNull()
      .references(() => accountsManualJournals.id, { onDelete: "cascade" }),
    entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
    fileName: varchar("file_name", { length: 255 }).notNull(),

    filePath: text("file_path").notNull(),
    fileSize: integer("file_size"),
    uploadedAt: timestamp("uploaded_at").defaultNow(),
  },
);

export const accountsJournalNumberSettings = pgTable(
  "journal_number_settings",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
    userId: uuid("user_id"),

    autoGenerate: boolean("auto_generate").default(true),
    prefix: varchar("prefix", { length: 20 }).default("MJ"),
    nextNumber: integer("next_number").default(1),
    isManualOverrideAllowed: boolean("is_manual_override_allowed").default(
      false,
    ),
    isActive: boolean("is_active").default(true),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
);

export const accountsJournalTemplates = pgTable("journal_templates", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  templateName: varchar("template_name", { length: 255 }).notNull(),

  referenceNumber: varchar("reference_number", { length: 255 }),
  notes: text("notes"),
  reportingMethod: varchar("reporting_method", { length: 50 }).default(
    "accrual_and_cash",
  ),
  currencyCode: varchar("currency_code", { length: 10 }).default("INR"),
  enterAmount: boolean("enter_amount").default(false),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const accountsJournalTemplateItems = pgTable(
  "journal_template_items",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    templateId: uuid("template_id")
      .notNull()
      .references(() => accountsJournalTemplates.id, { onDelete: "cascade" }),
    entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
    accountId: uuid("account_id").notNull(),

    description: text("description"),
    contactId: uuid("contact_id"),
    contactType: varchar("contact_type", { length: 50 }),
    type: varchar("type", { length: 50 }),
    debit: numeric("debit", { precision: 15, scale: 2 }).default("0.00"),
    credit: numeric("credit", { precision: 15, scale: 2 }).default("0.00"),
    sortOrder: integer("sort_order").default(0),
  },
);

export const accountsRecurringJournals = pgTable(
  "recurring_journals",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
    profileName: varchar("profile_name", { length: 255 }).notNull(),

    repeatEvery: varchar("repeat_every", { length: 50 }).notNull(),
    interval: integer("interval").default(1),
    startDate: date("start_date").notNull(),
    endDate: date("end_date"),
    neverExpires: boolean("never_expires").default(true),
    referenceNumber: varchar("reference_number", { length: 255 }),
    notes: text("notes"),
    currencyCode: varchar("currency_code", { length: 10 }).default("INR"),
    reportingMethod: varchar("reporting_method", { length: 50 }).default(
      "accrual_and_cash",
    ),
    createdById: uuid("created_by"),
    status: varchar("status", { length: 50 }).default("active"),
    lastGeneratedDate: date("last_generated_date"),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
);

export const accountsRecurringJournalItems = pgTable(
  "recurring_journal_items",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    recurringJournalId: uuid("recurring_journal_id")
      .notNull()
      .references(() => accountsRecurringJournals.id, { onDelete: "cascade" }),
    entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
    accountId: uuid("account_id").notNull(),
    description: text("description"),
    contactId: uuid("contact_id"),
    contactType: varchar("contact_type", { length: 50 }),
    contactName: varchar("contact_name", { length: 255 }),
    debit: numeric("debit", { precision: 15, scale: 2 }).default("0.00"),
    credit: numeric("credit", { precision: 15, scale: 2 }).default("0.00"),
    sortOrder: integer("sort_order").default(0),
  },
);



// Transaction Locking Table
export const transactionLocks = pgTable(
  "transaction_locks",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    orgId: uuid("org_id")
      .notNull()
      .default("00000000-0000-0000-0000-000000000000"),
    entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
    branchId: uuid("branch_id"),
    moduleName: varchar("module_name", { length: 100 }).notNull(),
    lockDate: timestamp("lock_date").notNull(),
    reason: text("reason"),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
  (table) => [
    unique("idx_org_module_lock").on(table.orgId, table.moduleName),
  ]
);

// =====================================
// INVENTORY MODULE
// =====================================
export const inventoryPicklists = pgTable("picklist_master", {
  id: uuid("id").primaryKey().defaultRandom(),
  picklistNumber: varchar("picklist_no").notNull().unique(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  date: date("picklist_date").notNull(),
  status: text("status"),
  assignee: uuid("assignee_id").references(() => users.id),
  warehouseId: uuid("warehouse_id")
    .notNull()
    .references(() => warehouses.id),
  notes: text("notes"),
  isDelete: boolean("is_delete").notNull().default(false),
  isEntrypass: boolean("is_entrypass").notNull().default(false),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const inventoryPicklistItems = pgTable("picklist_items", {
  id: uuid("id").primaryKey().defaultRandom(),
  picklistId: uuid("picklist_id")
    .notNull()
    .references(() => inventoryPicklists.id, { onDelete: "cascade" }),
  productId: uuid("product_id")
    .notNull()
    .references(() => product.id),
  salesOrderId: uuid("sales_order_id").references(() => salesOrder.id),
  salesOrderLineId: uuid("sales_order_line_id"),
  quantityOrdered: numeric("qty_ordered"),
  quantityToPick: numeric("qty_to_pick"),
  quantityPicked: numeric("qty_picked").default("0"),
  status: text("status"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const picklistBatchAllocation = pgTable("picklist_batch_allocation", {
  id: uuid("id").primaryKey().defaultRandom(),
  picklistItemId: uuid("picklist_item_id")
    .notNull()
    .references(() => inventoryPicklistItems.id, { onDelete: "cascade" }),
  batchId: uuid("batch_id")
    .notNull()
    .references(() => batches.id),
  layerId: varchar("layer_id").notNull(),
  warehouseId: uuid("warehouse_id")
    .notNull()
    .references(() => warehouses.id),
  binId: uuid("bin_id")
    .notNull()
    .references(() => bin.id),
  qty: numeric("qty").notNull(),
  focQty: numeric("foc_qty").default("0"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const inventoryAdjustmentReasons = pgTable("inventory_adjustment_reasons", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  name: varchar("name").notNull(),
  code: varchar("code"),
  reasonType: varchar("reason_type").default("both"),
  isActive: boolean("is_active").notNull().default(true),
  sortOrder: integer("sort_order").notNull().default(0),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const inventoryAdjustments = pgTable("inventory_adjustments", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  productId: uuid("product_id").references(() => product.id),
  warehouseId: uuid("warehouse_id").references(() => warehouses.id),
  adjustmentNumber: varchar("adjustment_number").unique(),
  adjustmentDate: timestamp("adjustment_date").notNull().defaultNow(),
  adjustmentType: varchar("adjustment_type").notNull().default("quantity"),
  reasonId: uuid("reason_id").references(() => inventoryAdjustmentReasons.id),
  reason: varchar("reason"),
  referenceNumber: varchar("reference_number"),
  notes: text("notes"),
  accountId: uuid("account_id").references(() => account.id),
  status: varchar("status").notNull().default("draft"),
  quantityBefore: numeric("quantity_before"),
  quantityAdjusted: numeric("quantity_adjusted"),
  quantityAfter: numeric("quantity_after"),
  costPrice: numeric("cost_price"),
  adjustmentValue: numeric("adjustment_value"),
  adjustedBy: uuid("adjusted_by").references(() => users.id),
  approvedBy: uuid("approved_by").references(() => users.id),
  approvedAt: timestamp("approved_at"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const inventoryAdjustmentItems = pgTable("inventory_adjustment_items", {
  id: uuid("id").primaryKey().defaultRandom(),
  adjustmentId: uuid("adjustment_id")
    .notNull()
    .references(() => inventoryAdjustments.id, { onDelete: "cascade" }),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  productId: uuid("product_id")
    .notNull()
    .references(() => product.id),
  quantityBefore: numeric("quantity_before").notNull().default("0"),
  quantityAdjusted: numeric("quantity_adjusted").notNull().default("0"),
  quantityAfter: numeric("quantity_after").notNull().default("0"),
  costPrice: numeric("cost_price"),
  purchaseRate: numeric("purchase_rate"),
  mrp: numeric("mrp"),
  adjustmentValue: numeric("adjustment_value").notNull().default("0"),
  batchId: uuid("batch_id").references(() => batches.id),
  batchReference: varchar("batch_reference"),
  batchAllocations: jsonb("batch_allocations").notNull().default([]),
  reportingTags: jsonb("reporting_tags").notNull().default({}),
  mfdMonthYear: varchar("mfd_month_year"),
  expiryMonthYear: varchar("expiry_month_year"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const inventoryAdjustmentItemBatches = pgTable("inventory_adjustment_item_batches", {
  id: uuid("id").primaryKey().defaultRandom(),
  adjustmentId: uuid("adjustment_id")
    .notNull()
    .references(() => inventoryAdjustments.id, { onDelete: "cascade" }),
  adjustmentItemId: uuid("adjustment_item_id")
    .notNull()
    .references(() => inventoryAdjustmentItems.id, { onDelete: "cascade" }),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  productId: uuid("product_id")
    .notNull()
    .references(() => product.id),
  warehouseId: uuid("warehouse_id").references(() => warehouses.id),
  binId: uuid("bin_id"),
  batchId: uuid("batch_id").references(() => batches.id),
  batchReference: varchar("batch_reference"),
  quantityIn: numeric("quantity_in").notNull().default("0"),
  quantityOut: numeric("quantity_out").notNull().default("0"),
  rate: numeric("rate"),
  batchStockLayerId: uuid("batch_stock_layer_id").references(() => batchStockLayers.id),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const inventoryAdjustmentAccountEntries = pgTable("inventory_adjustment_account_entries", {
  id: uuid("id").primaryKey().defaultRandom(),
  adjustmentId: uuid("adjustment_id")
    .notNull()
    .references(() => inventoryAdjustments.id, { onDelete: "cascade" }),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  accountId: uuid("account_id")
    .notNull()
    .references(() => account.id),
  debit: numeric("debit").notNull().default("0"),
  credit: numeric("credit").notNull().default("0"),
  description: text("description"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const inventoryAdjustmentAttachments = pgTable("inventory_adjustment_attachments", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  adjustmentId: uuid("adjustment_id")
    .notNull()
    .references(() => inventoryAdjustments.id, { onDelete: "cascade" }),
  fileName: text("file_name").notNull(),
  fileUrl: text("file_url"),
  storageBucket: text("storage_bucket"),
  storagePath: text("storage_path"),
  mimeType: text("mime_type"),
  fileSizeBytes: bigint("file_size_bytes", { mode: "number" }),
  fileHash: text("file_hash"),
  uploadedBy: uuid("uploaded_by").references(() => users.id),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const inventoryAdjustmentValueItems = pgTable("inventory_adjustment_value_items", {
  id: uuid("id").primaryKey().defaultRandom(),
  adjustmentId: uuid("adjustment_id")
    .notNull()
    .references(() => inventoryAdjustments.id, { onDelete: "cascade" }),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  productId: uuid("product_id")
    .notNull()
    .references(() => product.id),
  batchId: uuid("batch_id").references(() => batches.id),
  batchStockLayerId: uuid("batch_stock_layer_id").references(() => batchStockLayers.id),
  currentValue: numeric("current_value").notNull().default("0"),
  changedValue: numeric("changed_value").notNull().default("0"),
  adjustedValue: numeric("adjusted_value").notNull().default("0"),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});


// =====================================
// PACKAGING MODULE
// =====================================

export const inventoryPackages = pgTable("inventory_packages", {
  id: uuid("id").primaryKey().defaultRandom(),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  customerId: uuid("customer_id")
    .notNull()
    .references(() => customer.id),
  packageNumber: varchar("package_number").notNull().unique(),
  packageDate: date("package_date").default(sql`CURRENT_DATE`).notNull(),
  dimensionLength: numeric("dimension_length", { precision: 15, scale: 2 }).default("0"),
  dimensionWidth: numeric("dimension_width", { precision: 15, scale: 2 }).default("0"),
  dimensionHeight: numeric("dimension_height", { precision: 15, scale: 2 }).default("0"),
  dimensionUnit: varchar("dimension_unit", { length: 10 }).default("cm"),
  weight: numeric("weight", { precision: 15, scale: 2 }).default("0"),
  weightUnit: varchar("weight_unit", { length: 10 }).default("kg"),
  isManualMode: boolean("is_manual_mode").default(false),
  notes: text("notes"),
  status: varchar("status", { length: 50 }).default("Not Shipped"),
  createdAt: timestamp("created_at", { withTimezone: true, mode: "string" }).defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true, mode: "string" }).defaultNow(),
  isDelete: boolean("is_delete").notNull().default(false),
  createdBy: uuid("created_by"),
});

export const inventoryPackageItems = pgTable("inventory_package_items", {
  id: uuid("id").primaryKey().defaultRandom(),
  packageId: uuid("package_id")
    .notNull()
    .references(() => inventoryPackages.id, { onDelete: "cascade" }),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  productId: uuid("product_id")
    .notNull()
    .references(() => product.id),
  quantity: numeric("quantity", { precision: 15, scale: 3 }).default("0").notNull(),
  salesOrderId: uuid("sales_order_id").references(() => salesOrder.id),
  picklistId: uuid("picklist_id").references(() => inventoryPicklists.id),
});

export const inventoryPackageSalesOrders = pgTable("inventory_package_sales_orders", {
  packageId: uuid("package_id")
    .notNull()
    .references(() => inventoryPackages.id, { onDelete: "cascade" }),
  salesOrderId: uuid("sales_order_id")
    .notNull()
    .references(() => salesOrder.id),
  entityId: uuid("entity_id")
    .notNull()
    .references(() => organisationBranchMaster.id),
  binLocation: text("bin_location"),
  batchNo: varchar("batch_no", { length: 100 }),
}, (table) => [
  unique("inventory_package_sales_orders_pkey").on(table.packageId, table.salesOrderId),
]);



export const auditLogs = pgTable("audit_logs", {
  id: uuid("id").primaryKey().defaultRandom(),
  tableName: varchar("table_name", { length: 255 }).notNull(),
  recordId: uuid("record_id").notNull(),
  action: varchar("action", { length: 50 }).notNull(),
  oldValues: jsonb("old_values"),
  newValues: jsonb("new_values"),
  userId: uuid("user_id").notNull().default("00000000-0000-0000-0000-000000000000"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  orgId: uuid("org_id").notNull().default("00000000-0000-0000-0000-000000000000"),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  actorName: text("actor_name").notNull().default("system"),

  schemaName: text("schema_name").notNull().default("public"),
  recordPk: text("record_pk"),
  changedColumns: text("changed_columns").array(),
  txid: bigint("txid", { mode: "number" }).notNull(),
  source: text("source").notNull().default("system"),
  moduleName: text("module_name"),
  requestId: text("request_id"),
});

export const auditLogsArchive = pgTable("audit_logs_archive", {
  id: uuid("id").primaryKey().defaultRandom(),
  tableName: varchar("table_name", { length: 255 }).notNull(),
  recordId: uuid("record_id").notNull(),
  action: varchar("action", { length: 50 }).notNull(),
  oldValues: jsonb("old_values"),
  newValues: jsonb("new_values"),
  userId: uuid("user_id").notNull().default("00000000-0000-0000-0000-000000000000"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow(),
  orgId: uuid("org_id").notNull().default("00000000-0000-0000-0000-000000000000"),
  entityId: uuid("entity_id").references(() => organisationBranchMaster.id),
  actorName: text("actor_name").notNull().default("system"),

  schemaName: text("schema_name").notNull().default("public"),
  recordPk: text("record_pk"),
  changedColumns: text("changed_columns").array(),
  txid: bigint("txid", { mode: "number" }).notNull(),
  source: text("source").notNull().default("system"),
  moduleName: text("module_name"),
  requestId: text("request_id"),
  archivedAt: timestamp("archived_at", { withTimezone: true }).notNull().defaultNow(),
});


