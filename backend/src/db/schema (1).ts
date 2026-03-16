import { sql } from "drizzle-orm";
import {
  pgTable,
  uuid,
  varchar,
  text,
  decimal,
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

// Unit Table
export const unit = pgTable("units", {
  id: uuid("id").primaryKey().defaultRandom(),
  unitName: varchar("unit_name", { length: 50 }).notNull().unique(),
  unitSymbol: varchar("unit_symbol", { length: 10 }),
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

// Account Table
export const account = pgTable("accounts", {
  id: uuid("id").primaryKey().defaultRandom(),
  accountName: varchar("account_name", { length: 255 }).notNull(),
  accountType: varchar("account_type", { length: 50 }).notNull(), // Changed from enum to varchar for flexibility or update enum
  accountCode: varchar("account_code", { length: 50 }),
  parentId: uuid("parent_id").references(() => account.id),
  level: integer("level").default(0),
  description: text("description"),
  currency: varchar("currency", { length: 10 }).default("INR"),
  isActive: boolean("is_active").default(true),
  isSystem: boolean("is_system").default(false),
  isLocked: boolean("is_locked").default(false),
  showInExpense: boolean("show_in_expense").default(false),
  addToWatchlist: boolean("add_to_watchlist").default(false),
  createdAt: timestamp("created_at").defaultNow(),
});

// Account Transaction Table
export const accountTransaction = pgTable("account_transactions", {
  id: uuid("id").primaryKey().defaultRandom(),
  accountId: uuid("account_id")
    .notNull()
    .references(() => account.id, { onDelete: "cascade" }),
  transactionDate: timestamp("transaction_date").notNull(),
  transactionType: varchar("transaction_type", { length: 50 }),
  referenceNumber: varchar("reference_number", { length: 100 }),
  description: text("description"),
  debit: decimal("debit", { precision: 15, scale: 2 }).default("0.00"),
  credit: decimal("credit", { precision: 15, scale: 2 }).default("0.00"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Storage Location Table
export const storageLocation = pgTable("storage_locations", {
  id: uuid("id").primaryKey().defaultRandom(),
  locationName: varchar("location_name", { length: 255 }).notNull().unique(),
  temperatureRange: varchar("temperature_range", { length: 50 }),
  description: text("description"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Rack Table
export const rack = pgTable("racks", {
  id: uuid("id").primaryKey().defaultRandom(),
  rackCode: varchar("rack_code", { length: 50 }).notNull().unique(),
  rackName: varchar("rack_name", { length: 255 }),
  storageId: uuid("storage_id").references(() => storageLocation.id),
  capacity: integer("capacity"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});

// Reorder Term Table
export const reorderTerm = pgTable("reorder_terms", {
  id: uuid("id").primaryKey().defaultRandom(),
  termName: varchar("term_name", { length: 255 }).notNull().unique(),
  presetFormula: varchar("preset_formula", { length: 100 }),
  description: text("description"),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
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
  outletId: uuid("outlet_id"),
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
  billingAddressStreet1: text("billing_address_street_1"),
  billingAddressStreet2: text("billing_address_street_2"),
  billingCity: text("billing_city"),
  billingState: text("billing_state"),
  billingPincode: text("billing_pincode"),
  billingCountryRegion: text("billing_country_region"),
  billingPhone: text("billing_phone"),
  billingFax: text("billing_fax"),

  shippingAttention: text("shipping_attention"),
  shippingAddressStreet1: text("shipping_address_street_1"),
  shippingAddressStreet2: text("shipping_address_street_2"),
  shippingCity: text("shipping_city"),
  shippingState: text("shipping_state"),
  shippingPincode: text("shipping_pincode"),
  shippingCountryRegion: text("shipping_country_region"),
  shippingPhone: text("shipping_phone"),
  shippingFax: text("shipping_fax"),
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
export const strengths = pgTable("strengths", {
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
export const schedule = pgTable("schedules", {
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

  // Status Flags
  isActive: boolean("is_active").default(true),
  isLock: boolean("is_lock").default(false),

  // System Fields (no auth references for development)
  createdAt: timestamp("created_at").defaultNow(),
  createdById: uuid("created_by_id"),
  updatedAt: timestamp("updated_at").defaultNow(),
  updatedById: uuid("updated_by_id"),
});

// Product Composition Table
export const productComposition = pgTable("product_compositions", {
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
  orgId: uuid("org_id")
    .notNull()
    .default("00000000-0000-0000-0000-000000000000"), // Multi-tenancy
  outletId: uuid("outlet_id"), // Multi-tenancy: outlet ID (optional)
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
    precision: 15,
    scale: 2,
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
    precision: 15,
    scale: 2,
  }).default("0.00"),

  // Addresses
  billingAddressStreet1: varchar("billing_address_street1", { length: 255 }),
  billingAddressStreet2: varchar("billing_address_street2", { length: 255 }),
  billingAddressCity: varchar("billing_address_city", { length: 255 }),
  billingAddressState: varchar("billing_address_state", { length: 255 }),
  billingAddressZip: varchar("billing_address_zip", { length: 20 }),
  billingAddressCountry: varchar("billing_address_country", { length: 255 }),
  billingAddressPhone: varchar("billing_address_phone", { length: 50 }),

  shippingAddressStreet1: varchar("shipping_address_street1", { length: 255 }),
  shippingAddressStreet2: varchar("shipping_address_street2", { length: 255 }),
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
  customerId: uuid("customer_id")
    .notNull()
    .references(() => customer.id),
  saleNumber: varchar("sale_number", { length: 100 }).unique(),
  reference: varchar("reference", { length: 100 }),
  saleDate: timestamp("sale_date").defaultNow(),
  expectedShipmentDate: timestamp("expected_shipment_date"),
  deliveryMethod: varchar("delivery_method", { length: 100 }),
  paymentTerms: varchar("payment_terms", { length: 100 }),
  documentType: varchar("document_type", { length: 50 }).notNull(), // 'quote', 'order', 'invoice', etc.
  status: varchar("status", { length: 50 }).default("Draft"),
  total: decimal("total", { precision: 15, scale: 2 }).notNull(),
  currency: varchar("currency", { length: 20 }).default("INR"),
  customerNotes: text("customer_notes"),
  termsAndConditions: text("terms_and_conditions"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Sales Payment Table
export const salesPayment = pgTable("sales_payments", {
  id: uuid("id").primaryKey().defaultRandom(),
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
});

// Organization Table (Multi-tenancy Master)
// Outlet Inventory Table
export const outletInventory = pgTable(
  "outlet_inventory",
  {
    id: uuid().defaultRandom().primaryKey().notNull(),
    outletId: uuid("outlet_id").notNull(),
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
  },
  (table) => [
    index("idx_inventory_expiry").using(
      "btree",
      table.expiryDate.asc().nullsLast().op("date_ops"),
    ),
    index("idx_inventory_outlet").using(
      "btree",
      table.outletId.asc().nullsLast().op("uuid_ops"),
    ),
    index("idx_inventory_outlet_product").using(
      "btree",
      table.outletId.asc().nullsLast().op("uuid_ops"),
      table.productId.asc().nullsLast().op("uuid_ops"),
    ),
    index("idx_inventory_product").using(
      "btree",
      table.productId.asc().nullsLast().op("uuid_ops"),
    ),
    unique("outlet_inventory_outlet_id_product_id_batch_no_key").on(
      table.outletId,
      table.productId,
      table.batchNo,
    ),
    check("outlet_inventory_current_stock_check", sql`current_stock >= 0`),
  ],
);
export const organizations = pgTable("organizations", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull().unique(),
  orgCode: varchar("org_code", { length: 50 }).notNull().unique(),
  gstin: varchar("gstin", { length: 50 }),
  pan: varchar("pan", { length: 50 }),
  email: varchar("email", { length: 255 }),
  phone: varchar("phone", { length: 50 }),
  address: text("address"),
  city: varchar("city", { length: 100 }),
  state: varchar("state", { length: 100 }),
  country: varchar("country", { length: 100 }),
  pincode: varchar("pincode", { length: 20 }),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});
export const outlets = pgTable("outlets", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: uuid("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  name: varchar("name", { length: 255 }).notNull(),
  outletCode: varchar("outlet_code", { length: 50 }).notNull(),
  gstin: varchar("gstin", { length: 50 }),
  email: varchar("email", { length: 255 }),
  phone: varchar("phone", { length: 50 }),
  address: text("address"),
  city: varchar("city", { length: 100 }),
  state: varchar("state", { length: 100 }),
  country: varchar("country", { length: 100 }),
  pincode: varchar("pincode", { length: 20 }),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});
export const users = pgTable("users", {
  id: uuid("id").primaryKey(),
  email: varchar("email", { length: 255 }).notNull().unique(),
  fullName: varchar("full_name", { length: 255 }).notNull(),
  role: varchar("role", { length: 50 }).notNull().default("user"),
  orgId: uuid("org_id")
    .notNull()
    .references(() => organizations.id),
  isActive: boolean("is_active").default(true),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Transactional Sequences Table
export const transactionalSequence = pgTable("transactional_sequences", {
  id: uuid("id").primaryKey().defaultRandom(),
  module: varchar("module", { length: 50 }).notNull(), // removed .unique()
  prefix: varchar("prefix", { length: 20 }).notNull().default(""),
  nextNumber: integer("next_number").notNull().default(1),
  suffix: varchar("suffix", { length: 20 }).notNull().default(""),
  padding: integer("padding").notNull().default(6),
  outletId: uuid("outlet_id"),
  isActive: boolean("is_active").default(true),
  updatedAt: timestamp("updated_at").defaultNow(),
});
