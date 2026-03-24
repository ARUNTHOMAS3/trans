import { pgTable, foreignKey, uuid, varchar, date, numeric, boolean, timestamp, unique, index, jsonb, text, pgPolicy, integer, check, uniqueIndex, bigint, type AnyPgColumn, smallint, primaryKey, pgView, pgSequence, pgEnum } from "drizzle-orm/pg-core"
import { sql } from "drizzle-orm"

export const accountGroupEnum = pgEnum("account_group_enum", ['Assets', 'Liabilities', 'Equity', 'Income', 'Expenses'])
export const accountType = pgEnum("account_type", ['sales', 'purchase', 'inventory', 'expense', 'asset'])
export const accountTypeEnum = pgEnum("account_type_enum", ['Bank', 'Cash', 'Accounts Receivable', 'Stock', 'Payment Clearing Account', 'Other Current Asset', 'Fixed Asset', 'Non Current Asset', 'Intangible Asset', 'Deferred Tax Asset', 'Other Asset', 'Credit Card', 'Accounts Payable', 'Other Current Liability', 'Overseas Tax Payable', 'Non Current Liability', 'Deferred Tax Liability', 'Other Liability', 'Equity', 'Income', 'Other Income', 'Cost Of Goods Sold', 'Expense', 'Other Expense'])
export const accountsContactType = pgEnum("accounts_contact_type", ['customer', 'vendor'])
export const accountsJournalTemplateType = pgEnum("accounts_journal_template_type", ['debit', 'credit'])
export const accountsManualJournalStatus = pgEnum("accounts_manual_journal_status", ['draft', 'published'])
export const accountsReportingMethod = pgEnum("accounts_reporting_method", ['accrual_and_cash', 'accrual_only', 'cash_only'])
export const adjustmentMode = pgEnum("adjustment_mode", ['quantity', 'value'])
export const challanType = pgEnum("challan_type", ['supply', 'job_work', 'other'])
export const compositeType = pgEnum("composite_type", ['assembly', 'kit'])
export const hsnSacType = pgEnum("hsn_sac_type", ['HSN', 'SAC'])
export const inventoryValuationMethod = pgEnum("inventory_valuation_method", ['FIFO', 'LIFO', 'Weighted Average', 'Specific Identification', 'FEFO'])
export const locationType = pgEnum("location_type", ['business', 'warehouse'])
export const productType = pgEnum("product_type", ['goods', 'service'])
export const status = pgEnum("status", ['draft', 'active', 'inactive', 'sent', 'paid', 'void', 'open', 'delivered', 'invoiced', 'returned', 'assembled', 'not_shipped', 'shipped'])
export const taxPreference = pgEnum("tax_preference", ['taxable', 'non-taxable', 'exempt'])
export const taxType = pgEnum("tax_type", ['IGST', 'CGST', 'SGST'])
export const unitType = pgEnum("unit_type", ['count', 'weight', 'volume', 'length'])
export const vendorType = pgEnum("vendor_type", ['manufacturer', 'distributor', 'wholesaler'])

export const organizationSystemIdSeq = pgSequence("organization_system_id_seq", {  startWith: "60000000000", increment: "1", minValue: "1", maxValue: "9223372036854775807", cache: "1", cycle: false })

export const batches = pgTable("batches", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	productId: uuid("product_id"),
	batch: varchar({ length: 100 }).notNull(),
	exp: date().notNull(),
	mrp: numeric({ precision: 15, scale:  2 }).notNull(),
	ptr: numeric({ precision: 15, scale:  2 }).notNull(),
	unitPack: varchar("unit_pack"),
	isManufactureDetails: boolean("is_manufacture_details").default(false),
	manufactureBatchNumber: varchar("manufacture_batch_number", { length: 100 }),
	manufactureExp: date("manufacture_exp"),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "batches_product_id_fkey"
		}).onDelete("cascade"),
]);

export const taxGroups = pgTable("tax_groups", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	taxGroupName: varchar("tax_group_name", { length: 100 }).notNull(),
	taxRate: numeric("tax_rate", { precision: 5, scale:  2 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	unique("tax_groups_tax_group_name_key").on(table.taxGroupName),
]);

export const taxGroupTaxes = pgTable("tax_group_taxes", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	taxGroupId: uuid("tax_group_id"),
	taxId: uuid("tax_id"),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.taxGroupId],
			foreignColumns: [taxGroups.id],
			name: "tax_group_taxes_tax_group_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.taxId],
			foreignColumns: [associateTaxes.id],
			name: "tax_group_taxes_tax_id_fkey"
		}).onDelete("cascade"),
]);

export const manufacturers = pgTable("manufacturers", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 255 }).notNull(),
	contactInfo: jsonb("contact_info"),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_manufacturers_active_name").using("btree", table.isActive.asc().nullsLast().op("text_ops"), table.name.asc().nullsLast().op("text_ops")),
	index("idx_manufacturers_name_trgm").using("gin", sql`lower((name)::text)`),
	index("manufacturers_is_active_idx").using("btree", table.isActive.asc().nullsLast().op("bool_ops")),
	unique("manufacturers_name_unique").on(table.name),
]);

export const strengths = pgTable("strengths", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	strengthName: varchar("strength_name", { length: 100 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_strengths_active_name").using("btree", table.isActive.asc().nullsLast().op("bool_ops"), table.strengthName.asc().nullsLast().op("text_ops")),
	index("strengths_is_active_idx").using("btree", table.isActive.asc().nullsLast().op("bool_ops")),
	unique("strengths_strength_name_key").on(table.strengthName),
]);

export const contents = pgTable("contents", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	contentName: varchar("content_name", { length: 255 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_contents_active_name").using("btree", table.isActive.asc().nullsLast().op("text_ops"), table.contentName.asc().nullsLast().op("text_ops")),
	unique("contents_content_name_key").on(table.contentName),
]);

export const transactionLocks = pgTable("transaction_locks", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	moduleName: varchar("module_name", { length: 100 }).notNull(),
	lockDate: timestamp("lock_date", { mode: 'string' }).notNull(),
	reason: text(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	unique("idx_org_module_lock").on(table.orgId, table.moduleName),
]);

export const states = pgTable("states", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	stateId: uuid("state_id").notNull(),
	name: varchar({ length: 100 }).notNull(),
	code: varchar({ length: 10 }),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.stateId],
			foreignColumns: [countries.id],
			name: "states_state_id_fkey"
		}).onDelete("cascade"),
]);

export const salesPaymentLinks = pgTable("sales_payment_links", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	customerId: uuid("customer_id").notNull(),
	amount: numeric({ precision: 15, scale:  2 }).notNull(),
	linkUrl: text("link_url").notNull(),
	status: varchar({ length: 50 }).default('active'),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.customerId],
			foreignColumns: [customers.id],
			name: "sales_payment_links_customer_id_customers_id_fk"
		}),
]);

export const paymentTerms = pgTable("payment_terms", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	termName: varchar("term_name", { length: 255 }).notNull(),
	numberOfDays: integer("number_of_days").notNull(),
	description: text(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	unique("payment_terms_term_name_key").on(table.termName),
	pgPolicy("Allow all operations on payment_terms", { as: "permissive", for: "all", to: ["public"], using: sql`true`, withCheck: sql`true`  }),
]);

export const racks = pgTable("racks", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	rackCode: varchar("rack_code", { length: 50 }).notNull(),
	rackName: varchar("rack_name", { length: 255 }),
	storageId: uuid("storage_id"),
	capacity: integer(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_racks_active_code").using("btree", table.isActive.asc().nullsLast().op("text_ops"), table.rackCode.asc().nullsLast().op("text_ops")),
	unique("racks_rack_code_unique").on(table.rackCode),
]);

export const products = pgTable("products", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	type: productType().notNull(),
	productName: varchar("product_name", { length: 255 }).notNull(),
	billingName: varchar("billing_name", { length: 255 }),
	itemCode: varchar("item_code", { length: 100 }).notNull(),
	sku: varchar({ length: 100 }),
	unitId: uuid("unit_id").notNull(),
	categoryId: uuid("category_id"),
	isReturnable: boolean("is_returnable").default(false),
	pushToEcommerce: boolean("push_to_ecommerce").default(false),
	hsnCode: varchar("hsn_code", { length: 50 }),
	taxPreference: taxPreference("tax_preference"),
	intraStateTaxId: uuid("intra_state_tax_id"),
	interStateTaxId: uuid("inter_state_tax_id"),
	primaryImageUrl: text("primary_image_url"),
	imageUrls: jsonb("image_urls"),
	sellingPrice: numeric("selling_price", { precision: 15, scale:  2 }),
	sellingPriceCurrency: varchar("selling_price_currency", { length: 10 }).default('INR'),
	mrp: numeric({ precision: 15, scale:  2 }),
	ptr: numeric({ precision: 15, scale:  2 }),
	salesAccountId: uuid("sales_account_id"),
	salesDescription: text("sales_description"),
	costPrice: numeric("cost_price", { precision: 15, scale:  2 }),
	costPriceCurrency: varchar("cost_price_currency", { length: 10 }).default('INR'),
	purchaseAccountId: uuid("purchase_account_id"),
	preferredVendorId: uuid("preferred_vendor_id"),
	purchaseDescription: text("purchase_description"),
	length: numeric({ precision: 10, scale:  2 }),
	width: numeric({ precision: 10, scale:  2 }),
	height: numeric({ precision: 10, scale:  2 }),
	dimensionUnit: varchar("dimension_unit", { length: 10 }).default('cm'),
	weight: numeric({ precision: 10, scale:  2 }),
	weightUnit: varchar("weight_unit", { length: 10 }).default('kg'),
	manufacturerId: uuid("manufacturer_id"),
	brandId: uuid("brand_id"),
	mpn: varchar({ length: 100 }),
	upc: varchar({ length: 20 }),
	isbn: varchar({ length: 20 }),
	ean: varchar({ length: 20 }),
	trackAssocIngredients: boolean("track_assoc_ingredients").default(false),
	buyingRuleOld: varchar("buying_rule_old", { length: 100 }),
	scheduleOfDrugOld: varchar("schedule_of_drug_old", { length: 50 }),
	isTrackInventory: boolean("is_track_inventory").default(true),
	trackBinLocation: boolean("track_bin_location").default(false),
	trackBatches: boolean("track_batches").default(false),
	inventoryAccountId: uuid("inventory_account_id"),
	inventoryValuationMethod: inventoryValuationMethod("inventory_valuation_method"),
	storageId: uuid("storage_id"),
	rackId: uuid("rack_id"),
	reorderPoint: integer("reorder_point").default(0),
	reorderTermId: uuid("reorder_term_id"),
	isActive: boolean("is_active").default(true),
	isLock: boolean("is_lock").default(false),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	createdById: uuid("created_by_id"),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
	updatedById: uuid("updated_by_id"),
	trackSerialNumber: boolean("track_serial_number").default(false),
	buyingRuleId: uuid("buying_rule_id"),
	scheduleOfDrugId: uuid("schedule_of_drug_id"),
	lockUnitPack: numeric("lock_unit_pack", { precision: 15, scale:  2 }),
	storageDescription: text("storage_description"),
	about: text(),
	usesDescription: text("uses_description"),
	howToUse: text("how_to_use"),
	dosageDescription: text("dosage_description"),
	missedDoseDescription: text("missed_dose_description"),
	safetyAdvice: text("safety_advice"),
	sideEffects: jsonb("side_effects"),
	faqText: jsonb("faq_text"),
}, (table) => [
	index("idx_products_active_created_id").using("btree", table.isActive.asc().nullsLast().op("bool_ops"), table.createdAt.desc().nullsFirst().op("timestamp_ops"), table.id.desc().nullsFirst().op("bool_ops")),
	index("idx_products_ean").using("btree", table.ean.asc().nullsLast().op("text_ops")),
	index("idx_products_name_trgm").using("gin", sql`lower((product_name)::text)`),
	index("idx_products_sku").using("btree", table.sku.asc().nullsLast().op("text_ops")),
	foreignKey({
			columns: [table.brandId],
			foreignColumns: [brands.id],
			name: "products_brand_id_fkey"
		}),
	foreignKey({
			columns: [table.buyingRuleId],
			foreignColumns: [buyingRules.id],
			name: "products_buying_rule_id_buying_rules_id_fk"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.categoryId],
			foreignColumns: [categories.id],
			name: "products_category_id_fkey"
		}).onDelete("restrict"),
	foreignKey({
			columns: [table.interStateTaxId],
			foreignColumns: [associateTaxes.id],
			name: "products_inter_state_tax_id_fkey"
		}).onDelete("restrict"),
	foreignKey({
			columns: [table.intraStateTaxId],
			foreignColumns: [taxGroups.id],
			name: "products_intra_state_tax_id_fkey"
		}).onDelete("restrict"),
	foreignKey({
			columns: [table.inventoryAccountId],
			foreignColumns: [accounts.id],
			name: "products_inventory_account_id_accounts_id_fk"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.manufacturerId],
			foreignColumns: [manufacturers.id],
			name: "products_manufacturer_id_fkey"
		}).onDelete("restrict"),
	foreignKey({
			columns: [table.preferredVendorId],
			foreignColumns: [vendors.id],
			name: "products_preferred_vendor_id_vendors_id_fk"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.purchaseAccountId],
			foreignColumns: [accounts.id],
			name: "products_purchase_account_id_accounts_id_fk"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.rackId],
			foreignColumns: [racks.id],
			name: "products_rack_id_racks_id_fk"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.salesAccountId],
			foreignColumns: [accounts.id],
			name: "products_sales_account_id_accounts_id_fk"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.scheduleOfDrugId],
			foreignColumns: [schedules.id],
			name: "products_schedule_of_drug_id_schedules_id_fk"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.storageId],
			foreignColumns: [storageLocations.id],
			name: "products_storage_id_fkey"
		}).onDelete("restrict"),
	foreignKey({
			columns: [table.unitId],
			foreignColumns: [units.id],
			name: "products_unit_id_units_id_fk"
		}),
	unique("products_item_code_unique").on(table.itemCode),
	unique("products_sku_unique").on(table.sku),
	check("products_inventory_valuation_method_check", sql`(inventory_valuation_method IS NULL) OR (inventory_valuation_method = ANY (ARRAY['FIFO'::inventory_valuation_method, 'LIFO'::inventory_valuation_method, 'FEFO'::inventory_valuation_method, 'Weighted Average'::inventory_valuation_method, 'Specific Identification'::inventory_valuation_method]))`),
]);

export const associateTaxes = pgTable("associate_taxes", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	taxName: varchar("tax_name", { length: 100 }).notNull(),
	taxRate: numeric("tax_rate", { precision: 5, scale:  2 }).notNull(),
	taxType: taxType("tax_type"),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	unique("tax_rates_tax_name_unique").on(table.taxName),
]);

export const vendors = pgTable("vendors", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	vendorNumber: varchar("vendor_number", { length: 100 }),
	displayName: varchar("display_name", { length: 255 }).notNull(),
	salutation: varchar({ length: 20 }),
	firstName: varchar("first_name", { length: 255 }),
	lastName: varchar("last_name", { length: 255 }),
	companyName: varchar("company_name", { length: 255 }),
	email: varchar({ length: 255 }),
	phone: varchar({ length: 50 }),
	mobilePhone: varchar("mobile_phone", { length: 50 }),
	designation: varchar({ length: 255 }),
	department: varchar({ length: 255 }),
	website: varchar({ length: 255 }),
	vendorLanguage: varchar("vendor_language", { length: 50 }).default('English'),
	gstTreatment: varchar("gst_treatment", { length: 100 }),
	gstin: varchar({ length: 50 }),
	sourceOfSupply: varchar("source_of_supply", { length: 100 }),
	pan: varchar({ length: 50 }),
	currency: varchar({ length: 20 }).default('INR'),
	paymentTerms: varchar("payment_terms", { length: 100 }),
	isMsmeRegistered: boolean("is_msme_registered").default(false),
	msmeRegistrationType: varchar("msme_registration_type", { length: 100 }),
	msmeRegistrationNumber: varchar("msme_registration_number", { length: 100 }),
	isDrugRegistered: boolean("is_drug_registered").default(false),
	drugLicenceType: varchar("drug_licence_type", { length: 100 }),
	drugLicense20: varchar("drug_license_20", { length: 100 }),
	drugLicense21: varchar("drug_license_21", { length: 100 }),
	drugLicense20B: varchar("drug_license_20b", { length: 100 }),
	drugLicense21B: varchar("drug_license_21b", { length: 100 }),
	isFssaiRegistered: boolean("is_fssai_registered").default(false),
	fssaiNumber: varchar("fssai_number", { length: 100 }),
	tdsRateId: varchar("tds_rate_id", { length: 100 }),
	enablePortal: boolean("enable_portal").default(false),
	remarks: text(),
	xHandle: varchar("x_handle", { length: 255 }),
	facebookHandle: varchar("facebook_handle", { length: 255 }),
	whatsappNumber: varchar("whatsapp_number", { length: 255 }),
	source: varchar({ length: 50 }).default('User'),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
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
	priceListId: uuid("price_list_id"),
}, (table) => [
	index("idx_vendors_active_display_name").using("btree", table.isActive.asc().nullsLast().op("bool_ops"), table.displayName.asc().nullsLast().op("text_ops")),
	index("idx_vendors_display_name_trgm").using("gin", sql`lower((display_name)::text)`),
	unique("vendors_vendor_number_unique").on(table.vendorNumber),
]);

export const accountsRecurringJournals = pgTable("accounts_recurring_journals", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	profileName: varchar("profile_name").notNull(),
	repeatEvery: varchar("repeat_every").notNull(),
	interval: integer().default(1).notNull(),
	startDate: date("start_date").notNull(),
	endDate: date("end_date"),
	neverExpires: boolean("never_expires").default(true),
	referenceNumber: varchar("reference_number"),
	notes: text(),
	currencyCode: varchar("currency_code").default('INR'),
	reportingMethod: varchar("reporting_method").default('accrual_and_cash'),
	status: varchar().default('active'),
	lastGeneratedDate: timestamp("last_generated_date", { mode: 'string' }),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
	createdBy: uuid("created_by"),
});

export const salesEwayBills = pgTable("sales_eway_bills", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	saleId: uuid("sale_id"),
	billNumber: varchar("bill_number", { length: 100 }),
	billDate: timestamp("bill_date", { mode: 'string' }).defaultNow(),
	supplyType: varchar("supply_type", { length: 50 }).default('Outward'),
	subType: varchar("sub_type", { length: 50 }).default('Supply'),
	transporterId: varchar("transporter_id", { length: 100 }),
	vehicleNumber: varchar("vehicle_number", { length: 50 }),
	status: varchar({ length: 50 }).default('active'),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.saleId],
			foreignColumns: [salesOrders.id],
			name: "sales_eway_bills_sale_id_sales_orders_id_fk"
		}),
	unique("sales_eway_bills_bill_number_unique").on(table.billNumber),
]);

export const vendorContactPersons = pgTable("vendor_contact_persons", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	vendorId: uuid("vendor_id"),
	salutation: text(),
	firstName: text("first_name"),
	lastName: text("last_name"),
	email: text(),
	workPhone: text("work_phone"),
	mobilePhone: text("mobile_phone"),
	designation: text(),
	department: text(),
	isPrimary: boolean("is_primary").default(false),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.vendorId],
			foreignColumns: [vendors.id],
			name: "vendor_contact_persons_vendor_id_fkey"
		}).onDelete("cascade"),
]);

export const compositeItemParts = pgTable("composite_item_parts", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	compositeItemId: uuid("composite_item_id").notNull(),
	componentProductId: uuid("component_product_id").notNull(),
	quantity: numeric({ precision: 15, scale:  3 }).notNull(),
	sellingPriceOverride: numeric("selling_price_override", { precision: 15, scale:  2 }),
	costPriceOverride: numeric("cost_price_override", { precision: 15, scale:  2 }),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.componentProductId],
			foreignColumns: [products.id],
			name: "composite_item_parts_component_product_id_fkey"
		}),
	foreignKey({
			columns: [table.compositeItemId],
			foreignColumns: [compositeItems.id],
			name: "composite_item_parts_composite_item_id_fkey"
		}).onDelete("cascade"),
]);

export const accounts = pgTable("accounts", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	systemAccountName: varchar("system_account_name", { length: 255 }),
	accountCode: varchar("account_code", { length: 50 }),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	parentId: uuid("parent_id"),
	accountGroup: accountGroupEnum("account_group").default('Expenses').notNull(),
	isSystem: boolean("is_system").default(false),
	accountType: accountTypeEnum("account_type").notNull(),
	description: text(),
	accountNumber: varchar("account_number", { length: 100 }),
	ifsc: varchar({ length: 20 }),
	currency: varchar({ length: 10 }).default('INR'),
	showInZerpaiExpense: boolean("show_in_zerpai_expense").default(false),
	addToWatchlist: boolean("add_to_watchlist").default(false),
	isDeletable: boolean("is_deletable").default(true),
	userAccountName: varchar("user_account_name", { length: 255 }),
	createdBy: uuid("created_by"),
	isDeleted: boolean("is_deleted").default(false),
	modifiedAt: timestamp("modified_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	modifiedBy: uuid("modified_by"),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
}, (table) => [
	index("idx_accounts_active_system_name").using("btree", table.isActive.asc().nullsLast().op("text_ops"), table.systemAccountName.asc().nullsLast().op("bool_ops")),
	index("idx_accounts_active_user_name").using("btree", table.isActive.asc().nullsLast().op("text_ops"), table.userAccountName.asc().nullsLast().op("text_ops")),
	index("idx_accounts_group").using("btree", table.accountGroup.asc().nullsLast().op("enum_ops")),
	index("idx_accounts_lookup_name_trgm").using("gin", sql`lower((COALESCE(user_account_name, system_account_name))::text)`),
	index("idx_accounts_parent").using("btree", table.parentId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.parentId],
			foreignColumns: [table.id],
			name: "fk_accounts_parent"
		}).onDelete("cascade"),
	unique("accounts_system_name_unique").on(table.systemAccountName),
	unique("accounts_account_code_unique").on(table.accountCode),
	check("chk_account_group_type_match", sql`((account_group = 'Assets'::account_group_enum) AND (account_type = ANY (ARRAY['Bank'::account_type_enum, 'Cash'::account_type_enum, 'Accounts Receivable'::account_type_enum, 'Stock'::account_type_enum, 'Payment Clearing Account'::account_type_enum, 'Other Current Asset'::account_type_enum, 'Fixed Asset'::account_type_enum, 'Non Current Asset'::account_type_enum, 'Intangible Asset'::account_type_enum, 'Deferred Tax Asset'::account_type_enum, 'Other Asset'::account_type_enum]))) OR ((account_group = 'Liabilities'::account_group_enum) AND (account_type = ANY (ARRAY['Credit Card'::account_type_enum, 'Accounts Payable'::account_type_enum, 'Other Current Liability'::account_type_enum, 'Overseas Tax Payable'::account_type_enum, 'Non Current Liability'::account_type_enum, 'Deferred Tax Liability'::account_type_enum, 'Other Liability'::account_type_enum]))) OR ((account_group = 'Equity'::account_group_enum) AND (account_type = 'Equity'::account_type_enum)) OR ((account_group = 'Income'::account_group_enum) AND (account_type = ANY (ARRAY['Income'::account_type_enum, 'Other Income'::account_type_enum]))) OR ((account_group = 'Expenses'::account_group_enum) AND (account_type = ANY (ARRAY['Cost Of Goods Sold'::account_type_enum, 'Expense'::account_type_enum, 'Other Expense'::account_type_enum])))`),
]);

export const shipmentPreferences = pgTable("shipment_preferences", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 100 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	unique("shipment_preferences_name_key").on(table.name),
]);

export const brands = pgTable("brands", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 255 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_brands_active_name").using("btree", table.isActive.asc().nullsLast().op("bool_ops"), table.name.asc().nullsLast().op("bool_ops")),
	index("idx_brands_name_trgm").using("gin", sql`lower((name)::text)`),
	unique("brands_name_unique").on(table.name),
]);

export const salesOrders = pgTable("sales_orders", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	customerId: uuid("customer_id").notNull(),
	saleNumber: varchar("sale_number", { length: 100 }),
	reference: varchar({ length: 100 }),
	saleDate: timestamp("sale_date", { mode: 'string' }).defaultNow(),
	expectedShipmentDate: timestamp("expected_shipment_date", { mode: 'string' }),
	deliveryMethod: varchar("delivery_method", { length: 100 }),
	paymentTerms: varchar("payment_terms", { length: 100 }),
	documentType: varchar("document_type", { length: 50 }).notNull(),
	status: varchar({ length: 50 }).default('Draft'),
	total: numeric({ precision: 15, scale:  2 }).notNull(),
	currency: varchar({ length: 20 }).default('INR'),
	customerNotes: text("customer_notes"),
	termsAndConditions: text("terms_and_conditions"),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.customerId],
			foreignColumns: [customers.id],
			name: "sales_orders_customer_id_customers_id_fk"
		}),
	unique("sales_orders_sale_number_unique").on(table.saleNumber),
]);

export const vendorBankAccounts = pgTable("vendor_bank_accounts", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	vendorId: uuid("vendor_id"),
	holderName: text("holder_name"),
	bankName: text("bank_name"),
	accountNumber: text("account_number"),
	ifsc: text(),
	isPrimary: boolean("is_primary").default(false),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.vendorId],
			foreignColumns: [vendors.id],
			name: "vendor_bank_accounts_vendor_id_fkey"
		}).onDelete("cascade"),
]);

export const tdsRates = pgTable("tds_rates", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	taxName: varchar("tax_name", { length: 255 }).notNull(),
	sectionId: uuid("section_id"),
	baseRate: numeric("base_rate", { precision: 5, scale:  2 }).notNull(),
	surchargeRate: numeric("surcharge_rate", { precision: 5, scale:  2 }).default('0.00'),
	cessRate: numeric("cess_rate", { precision: 5, scale:  2 }).default('0.00'),
	payableAccountId: uuid("payable_account_id"),
	receivableAccountId: uuid("receivable_account_id"),
	isHigherRate: boolean("is_higher_rate").default(false),
	reasonHigherRate: text("reason_higher_rate"),
	applicableFrom: timestamp("applicable_from", { mode: 'string' }),
	applicableTo: timestamp("applicable_to", { mode: 'string' }),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.payableAccountId],
			foreignColumns: [accounts.id],
			name: "tds_rates_payable_account_id_fkey"
		}),
	foreignKey({
			columns: [table.receivableAccountId],
			foreignColumns: [accounts.id],
			name: "tds_rates_receivable_account_id_fkey"
		}),
	foreignKey({
			columns: [table.sectionId],
			foreignColumns: [tdsSections.id],
			name: "tds_rates_section_id_fkey"
		}),
	unique("tds_rates_tax_name_unique").on(table.taxName),
	pgPolicy("Allow all operations on tds_rates", { as: "permissive", for: "all", to: ["public"], using: sql`true`, withCheck: sql`true`  }),
]);

export const units = pgTable("units", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	unitName: varchar("unit_name", { length: 50 }).notNull(),
	unitType: unitType("unit_type"),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	unitSymbol: varchar("unit_symbol", { length: 10 }),
	uqcId: uuid("uqc_id"),
}, (table) => [
	foreignKey({
			columns: [table.uqcId],
			foreignColumns: [uqc.id],
			name: "units_uqc_id_fkey"
		}),
	unique("units_unit_name_unique").on(table.unitName),
]);

export const accountsRecurringJournalItems = pgTable("accounts_recurring_journal_items", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	recurringJournalId: uuid("recurring_journal_id").notNull(),
	accountId: uuid("account_id").notNull(),
	description: text(),
	contactId: uuid("contact_id"),
	contactType: varchar("contact_type"),
	debit: numeric().default('0.00'),
	credit: numeric().default('0.00'),
	sortOrder: integer("sort_order"),
	contactName: varchar("contact_name", { length: 255 }),
}, (table) => [
	foreignKey({
			columns: [table.accountId],
			foreignColumns: [accounts.id],
			name: "accounts_recurring_journal_items_account_id_fkey"
		}),
	foreignKey({
			columns: [table.recurringJournalId],
			foreignColumns: [accountsRecurringJournals.id],
			name: "accounts_recurring_journal_items_recur_journal_id_fkey"
		}).onDelete("cascade"),
]);

export const reorderTerms = pgTable("reorder_terms", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	termName: varchar("term_name", { length: 255 }).notNull(),
	description: text(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	quantity: integer().default(1).notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_reorder_terms_active_name").using("btree", table.isActive.asc().nullsLast().op("bool_ops"), table.termName.asc().nullsLast().op("text_ops")),
	uniqueIndex("idx_reorder_terms_org_outlet_term_name").using("btree", sql`org_id`, sql`outlet_id`, sql`lower((term_name)::text)`).where(sql`(outlet_id IS NOT NULL)`),
	uniqueIndex("idx_reorder_terms_org_term_name_global").using("btree", sql`org_id`, sql`lower((term_name)::text)`).where(sql`(outlet_id IS NULL)`),
	check("reorder_terms_quantity_positive", sql`quantity > 0`),
]);

export const schedules = pgTable("schedules", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	sheduleName: varchar("shedule_name", { length: 100 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	scheduleCode: varchar("schedule_code", { length: 30 }),
	referenceDescription: text("reference_description"),
	requiresPrescription: boolean("requires_prescription").default(false).notNull(),
	requiresH1Register: boolean("requires_h1_register").default(false).notNull(),
	isNarcotic: boolean("is_narcotic").default(false).notNull(),
	requiresBatchTracking: boolean("requires_batch_tracking").default(false).notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
	isCommon: boolean("is_common").default(false).notNull(),
}, (table) => [
	index("idx_schedules_active_name").using("btree", table.isActive.asc().nullsLast().op("text_ops"), table.sheduleName.asc().nullsLast().op("text_ops")),
	unique("schedules_shedule_name_key").on(table.sheduleName),
]);

export const auditLogs = pgTable("audit_logs", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	tableName: varchar("table_name", { length: 100 }).notNull(),
	recordId: uuid("record_id").notNull(),
	action: varchar({ length: 10 }).notNull(),
	oldValues: jsonb("old_values"),
	newValues: jsonb("new_values"),
	userId: uuid("user_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	actorName: text("actor_name").default('system').notNull(),
	schemaName: text("schema_name").default('public').notNull(),
	recordPk: text("record_pk"),
	changedColumns: text("changed_columns").array(),
	// You can use { mode: "bigint" } if numbers are exceeding js number limitations
	txid: bigint({ mode: "number" }).default(sql`txid_current()`).notNull(),
	source: text().default('system').notNull(),
	moduleName: text("module_name"),
	requestId: text("request_id"),
}, (table) => [
	index("idx_audit_logs_action_created").using("btree", table.action.asc().nullsLast().op("timestamptz_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	index("idx_audit_logs_org_created").using("btree", table.orgId.asc().nullsLast().op("timestamptz_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	index("idx_audit_logs_record_pk").using("btree", table.tableName.asc().nullsLast().op("text_ops"), table.recordPk.asc().nullsLast().op("text_ops")),
	index("idx_audit_logs_request_id").using("btree", table.requestId.asc().nullsLast().op("text_ops")),
	index("idx_audit_logs_schema_table_record").using("btree", table.schemaName.asc().nullsLast().op("uuid_ops"), table.tableName.asc().nullsLast().op("text_ops"), table.recordId.asc().nullsLast().op("uuid_ops")),
	index("idx_audit_logs_table_record").using("btree", table.tableName.asc().nullsLast().op("uuid_ops"), table.recordId.asc().nullsLast().op("uuid_ops")),
	index("idx_audit_logs_table_record_pk").using("btree", table.tableName.asc().nullsLast().op("text_ops"), table.recordPk.asc().nullsLast().op("text_ops")),
	index("idx_audit_logs_user_created").using("btree", table.userId.asc().nullsLast().op("timestamptz_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	pgPolicy("audit_logs_read_all", { as: "permissive", for: "select", to: ["anon", "authenticated", "service_role"], using: sql`true` }),
]);

export const auditLogsArchive = pgTable("audit_logs_archive", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	tableName: varchar("table_name", { length: 100 }).notNull(),
	recordId: uuid("record_id").notNull(),
	action: varchar({ length: 10 }).notNull(),
	oldValues: jsonb("old_values"),
	newValues: jsonb("new_values"),
	userId: uuid("user_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	actorName: text("actor_name").default('system').notNull(),
	schemaName: text("schema_name").default('public').notNull(),
	recordPk: text("record_pk"),
	changedColumns: text("changed_columns"),
	// You can use { mode: "bigint" } if numbers are exceeding js number limitations
	txid: bigint({ mode: "number" }).default(sql`txid_current()`).notNull(),
	source: text().default('system').notNull(),
	moduleName: text("module_name"),
	requestId: text("request_id"),
	archivedAt: timestamp("archived_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("audit_logs_archive_action_created_at_idx").using("btree", table.action.asc().nullsLast().op("timestamptz_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	index("audit_logs_archive_org_id_created_at_idx").using("btree", table.orgId.asc().nullsLast().op("uuid_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	index("audit_logs_archive_table_name_record_id_idx").using("btree", table.tableName.asc().nullsLast().op("uuid_ops"), table.recordId.asc().nullsLast().op("uuid_ops")),
	index("audit_logs_archive_table_name_record_pk_idx").using("btree", table.tableName.asc().nullsLast().op("text_ops"), table.recordPk.asc().nullsLast().op("text_ops")),
	index("audit_logs_archive_user_id_created_at_idx").using("btree", table.userId.asc().nullsLast().op("uuid_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	index("idx_audit_logs_archive_org_created").using("btree", table.orgId.asc().nullsLast().op("timestamptz_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	index("idx_audit_logs_archive_request_id").using("btree", table.requestId.asc().nullsLast().op("text_ops")),
	pgPolicy("audit_logs_archive_read_all", { as: "permissive", for: "select", to: ["anon", "authenticated", "service_role"], using: sql`true` }),
]);

export const buyingRules = pgTable("buying_rules", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	buyingRule: varchar("buying_rule", { length: 255 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	ruleDescription: text("rule_description"),
	systemBehavior: text("system_behavior"),
	associatedScheduleCodes: text("associated_schedule_codes").array().default(["RAY"]).notNull(),
	requiresRx: boolean("requires_rx").default(false).notNull(),
	requiresPatientInfo: boolean("requires_patient_info").default(false).notNull(),
	isSaleable: boolean("is_saleable").default(true).notNull(),
	logToSpecialRegister: boolean("log_to_special_register").default(false).notNull(),
	requiresDoctorName: boolean("requires_doctor_name").default(false).notNull(),
	requiresPrescriptionDate: boolean("requires_prescription_date").default(false).notNull(),
	requiresAgeCheck: boolean("requires_age_check").default(false).notNull(),
	institutionalOnly: boolean("institutional_only").default(false).notNull(),
	blocksRetailSale: boolean("blocks_retail_sale").default(false).notNull(),
	quantityLimit: integer("quantity_limit"),
	allowsRefill: boolean("allows_refill").default(false).notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
}, (table) => [
	index("idx_buying_rules_active_name").using("btree", table.isActive.asc().nullsLast().op("text_ops"), table.buyingRule.asc().nullsLast().op("text_ops")),
	unique("buying_rules_buying_rule_key").on(table.buyingRule),
]);

export const priceLists = pgTable("price_lists", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 255 }).notNull(),
	description: text().default(''),
	currency: varchar({ length: 20 }).default('INR'),
	pricingScheme: varchar("pricing_scheme", { length: 50 }).notNull(),
	details: text().default(''),
	roundOffPreference: varchar("round_off_preference", { length: 50 }).default('never_mind'),
	status: varchar({ length: 20 }).default('active'),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	priceListType: varchar("price_list_type", { length: 50 }).default('all_items'),
	percentageType: varchar("percentage_type", { length: 20 }),
	percentageValue: numeric("percentage_value", { precision: 5, scale:  2 }),
	discountEnabled: boolean("discount_enabled").default(false),
	transactionType: varchar("transaction_type", { length: 50 }).default('Sales'),
});

export const categories = pgTable("categories", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 255 }).notNull(),
	description: text(),
	parentId: uuid("parent_id"),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_categories_active_name").using("btree", table.isActive.asc().nullsLast().op("text_ops"), table.name.asc().nullsLast().op("text_ops")),
	foreignKey({
			columns: [table.parentId],
			foreignColumns: [table.id],
			name: "categories_parent_id_categories_id_fk"
		}),
	unique("categories_name_unique").on(table.name),
]);

export const salesPayments = pgTable("sales_payments", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	customerId: uuid("customer_id").notNull(),
	paymentNumber: varchar("payment_number", { length: 100 }),
	paymentDate: timestamp("payment_date", { mode: 'string' }).defaultNow(),
	paymentMode: varchar("payment_mode", { length: 50 }),
	amount: numeric({ precision: 15, scale:  2 }).notNull(),
	bankCharges: numeric("bank_charges", { precision: 15, scale:  2 }).default('0.00'),
	reference: varchar({ length: 100 }),
	depositTo: varchar("deposit_to", { length: 100 }),
	notes: text(),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.customerId],
			foreignColumns: [customers.id],
			name: "sales_payments_customer_id_customers_id_fk"
		}),
	unique("sales_payments_payment_number_unique").on(table.paymentNumber),
]);

export const currencies = pgTable("currencies", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	code: varchar({ length: 10 }).notNull(),
	name: varchar({ length: 100 }).notNull(),
	symbol: varchar({ length: 10 }),
	decimals: integer().default(2),
	format: varchar({ length: 50 }),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	unique("currencies_code_key").on(table.code),
]);

export const tdsGroups = pgTable("tds_groups", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	groupName: varchar("group_name", { length: 255 }).notNull(),
	applicableFrom: timestamp("applicable_from", { mode: 'string' }),
	applicableTo: timestamp("applicable_to", { mode: 'string' }),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	unique("tds_groups_group_name_unique").on(table.groupName),
	pgPolicy("Allow all operations on tds_groups", { as: "permissive", for: "all", to: ["public"], using: sql`true`, withCheck: sql`true`  }),
]);

export const countries = pgTable("countries", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 100 }).notNull(),
	fullLabel: varchar("full_label", { length: 255 }),
	phoneCode: varchar("phone_code", { length: 20 }).notNull(),
	shortCode: varchar("short_code", { length: 10 }),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	primaryTimezoneId: uuid("primary_timezone_id"),
}, (table) => [
	foreignKey({
			columns: [table.primaryTimezoneId],
			foreignColumns: [timezones.id],
			name: "countries_primary_timezone_id_fkey"
		}).onDelete("set null"),
	unique("countries_name_key").on(table.name),
]);

export const tdsSections = pgTable("tds_sections", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	sectionName: varchar("section_name", { length: 100 }).notNull(),
	description: text(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	unique("tds_sections_section_name_unique").on(table.sectionName),
	pgPolicy("Allow all operations on tds_sections", { as: "permissive", for: "all", to: ["public"], using: sql`true`, withCheck: sql`true`  }),
]);

export const tdsGroupItems = pgTable("tds_group_items", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	tdsGroupId: uuid("tds_group_id"),
	tdsRateId: uuid("tds_rate_id"),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.tdsGroupId],
			foreignColumns: [tdsGroups.id],
			name: "tds_group_items_tds_group_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.tdsRateId],
			foreignColumns: [tdsRates.id],
			name: "tds_group_items_tds_rate_id_fkey"
		}).onDelete("cascade"),
	pgPolicy("Allow all operations on tds_group_items", { as: "permissive", for: "all", to: ["public"], using: sql`true`, withCheck: sql`true`  }),
]);

export const accountsManualJournals = pgTable("accounts_manual_journals", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	journalNumber: varchar("journal_number", { length: 100 }).notNull(),
	fiscalYearId: uuid("fiscal_year_id"),
	referenceNumber: varchar("reference_number", { length: 100 }),
	journalDate: date("journal_date").default(sql`CURRENT_DATE`),
	notes: text(),
	is13ThMonthAdjustment: boolean("is_13th_month_adjustment").default(false),
	reportingMethod: accountsReportingMethod("reporting_method").default('accrual_and_cash'),
	currencyCode: varchar("currency_code", { length: 10 }).default('INR'),
	status: accountsManualJournalStatus().default('draft'),
	totalAmount: numeric("total_amount", { precision: 15, scale:  2 }).default('0.00'),
	createdBy: uuid("created_by"),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	recurringJournalId: uuid("recurring_journal_id"),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	isDeleted: boolean("is_deleted").default(false).notNull(),
}, (table) => [
	index("idx_accounts_manual_journals_org_is_deleted").using("btree", table.orgId.asc().nullsLast().op("bool_ops"), table.isDeleted.asc().nullsLast().op("bool_ops")),
	foreignKey({
			columns: [table.fiscalYearId],
			foreignColumns: [accountsFiscalYears.id],
			name: "accounts_manual_journals_fiscal_year_id_fkey"
		}),
	foreignKey({
			columns: [table.recurringJournalId],
			foreignColumns: [accountsRecurringJournals.id],
			name: "accounts_manual_journals_recurring_journal_id_fkey"
		}).onDelete("set null"),
	unique("accounts_manual_journals_journal_number_unique").on(table.journalNumber),
]);

export const accountsJournalNumberSettings = pgTable("accounts_journal_number_settings", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	autoGenerate: boolean("auto_generate").default(true),
	prefix: varchar({ length: 20 }),
	nextNumber: integer("next_number").default(1),
	isManualOverrideAllowed: boolean("is_manual_override_allowed").default(false),
	userId: uuid("user_id"),
}, (table) => [
	uniqueIndex("accounts_journal_number_settings_scope_uq").using("btree", sql`org_id`, sql`COALESCE(outlet_id, '00000000-0000-0000-0000-000000000000'::uui`, sql`COALESCE(user_id, '00000000-0000-0000-0000-000000000000'::uuid)`),
]);

export const accountsJournalTemplates = pgTable("accounts_journal_templates", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	templateName: varchar("template_name", { length: 255 }).notNull(),
	referenceNumber: varchar("reference_number", { length: 100 }),
	notes: text(),
	reportingMethod: accountsReportingMethod("reporting_method"),
	currencyCode: varchar("currency_code", { length: 10 }).default('INR'),
	isActive: boolean("is_active").default(true),
	enterAmount: boolean("enter_amount").default(false),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
});

export const accountsJournalTemplateItems = pgTable("accounts_journal_template_items", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	templateId: uuid("template_id").notNull(),
	accountId: uuid("account_id").notNull(),
	description: text(),
	contactId: uuid("contact_id"),
	contactType: accountsContactType("contact_type"),
	type: accountsJournalTemplateType(),
	debit: numeric({ precision: 15, scale:  2 }).default('0.00'),
	credit: numeric({ precision: 15, scale:  2 }).default('0.00'),
	sortOrder: integer("sort_order"),
}, (table) => [
	foreignKey({
			columns: [table.accountId],
			foreignColumns: [accounts.id],
			name: "accounts_journal_template_items_account_id_fkey"
		}),
	foreignKey({
			columns: [table.templateId],
			foreignColumns: [accountsJournalTemplates.id],
			name: "accounts_journal_template_items_template_id_fkey"
		}).onDelete("cascade"),
]);

export const accountsManualJournalItems = pgTable("accounts_manual_journal_items", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	manualJournalId: uuid("manual_journal_id").notNull(),
	accountId: uuid("account_id").notNull(),
	description: text(),
	contactId: uuid("contact_id"),
	contactType: accountsContactType("contact_type"),
	debit: numeric({ precision: 15, scale:  2 }).default('0.00'),
	credit: numeric({ precision: 15, scale:  2 }).default('0.00'),
	sortOrder: integer("sort_order"),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	contactName: varchar("contact_name", { length: 255 }),
}, (table) => [
	foreignKey({
			columns: [table.accountId],
			foreignColumns: [accounts.id],
			name: "accounts_manual_journal_items_account_id_fkey"
		}),
	foreignKey({
			columns: [table.manualJournalId],
			foreignColumns: [accountsManualJournals.id],
			name: "accounts_manual_journal_items_manual_journal_id_fkey"
		}).onDelete("cascade"),
]);

export const accountTransactions = pgTable("account_transactions", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	accountId: uuid("account_id").notNull(),
	transactionDate: timestamp("transaction_date", { mode: 'string' }).defaultNow().notNull(),
	transactionType: varchar("transaction_type", { length: 50 }),
	referenceNumber: varchar("reference_number", { length: 100 }),
	description: text(),
	debit: numeric({ precision: 15, scale:  2 }).default('0.00'),
	credit: numeric({ precision: 15, scale:  2 }).default('0.00'),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	sourceId: uuid("source_id"),
	sourceType: varchar("source_type", { length: 50 }),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	contactId: uuid("contact_id"),
	contactType: varchar("contact_type", { length: 50 }),
}, (table) => [
	index("idx_account_transactions_contact_id").using("btree", table.contactId.asc().nullsLast().op("uuid_ops")),
	index("idx_account_transactions_contact_type").using("btree", table.contactType.asc().nullsLast().op("text_ops")),
	foreignKey({
			columns: [table.accountId],
			foreignColumns: [accounts.id],
			name: "account_transactions_account_id_fkey"
		}).onDelete("cascade"),
]);

export const accountsManualJournalAttachments = pgTable("accounts_manual_journal_attachments", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	manualJournalId: uuid("manual_journal_id").notNull(),
	fileName: varchar("file_name", { length: 255 }).notNull(),
	filePath: text("file_path").notNull(),
	fileSize: integer("file_size"),
	uploadedAt: timestamp("uploaded_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.manualJournalId],
			foreignColumns: [accountsManualJournals.id],
			name: "accounts_manual_journal_attachments_manual_journal_id_fkey"
		}).onDelete("cascade"),
]);

export const accountsReportingTags = pgTable("accounts_reporting_tags", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	tagName: varchar("tag_name", { length: 100 }).notNull(),
	isActive: boolean("is_active").default(true),
});

export const transactionalSequences = pgTable("transactional_sequences", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	module: varchar({ length: 50 }).notNull(),
	prefix: varchar({ length: 20 }).default('').notNull(),
	nextNumber: integer("next_number").default(1).notNull(),
	padding: integer().default(6).notNull(),
	isActive: boolean("is_active").default(true),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	suffix: varchar({ length: 20 }).default(''),
	outletId: uuid("outlet_id"),
	isAuto: boolean("is_auto").default(true),
}, (table) => [
	uniqueIndex("idx_sequences_module_global").using("btree", table.module.asc().nullsLast().op("text_ops")).where(sql`(outlet_id IS NULL)`),
	uniqueIndex("idx_sequences_module_outlet").using("btree", table.module.asc().nullsLast().op("text_ops"), table.outletId.asc().nullsLast().op("text_ops")).where(sql`(outlet_id IS NOT NULL)`),
]);

export const warehouses = pgTable("warehouses", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id"),
	name: varchar({ length: 255 }).notNull(),
	attention: text(),
	addressStreet1: text("address_street_1"),
	addressStreet2: text("address_street_2"),
	city: text(),
	state: text(),
	zipCode: varchar("zip_code", { length: 20 }),
	countryRegion: text("country_region").notNull(),
	phone: varchar({ length: 50 }),
	email: varchar({ length: 255 }),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
	outletId: uuid("outlet_id"),
}, (table) => [
	foreignKey({
			columns: [table.orgId],
			foreignColumns: [organization.id],
			name: "warehouses_org_id_fkey"
		}),
]);

export const productContents = pgTable("product_contents", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	productId: uuid("product_id").notNull(),
	contentId: uuid("content_id"),
	strengthId: uuid("strength_id"),
	sheduleId: uuid("shedule_id"),
	displayOrder: integer("display_order").default(0),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.contentId],
			foreignColumns: [contents.id],
			name: "product_contents_content_id_fkey"
		}),
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "product_contents_product_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.sheduleId],
			foreignColumns: [schedules.id],
			name: "product_contents_schedule_id_fkey"
		}),
	foreignKey({
			columns: [table.strengthId],
			foreignColumns: [strengths.id],
			name: "product_contents_strength_id_fkey"
		}),
]);

export const storageLocations = pgTable("storage_locations", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	locationName: varchar("location_name", { length: 255 }).notNull(),
	temperatureRange: varchar("temperature_range", { length: 50 }),
	description: text(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	displayText: varchar("display_text", { length: 255 }),
	commonExamples: text("common_examples"),
	minTempC: numeric("min_temp_c", { precision: 5, scale:  2 }),
	maxTempC: numeric("max_temp_c", { precision: 5, scale:  2 }),
	isColdChain: boolean("is_cold_chain").default(false).notNull(),
	requiresFridge: boolean("requires_fridge").default(false).notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
	storageType: varchar("storage_type", { length: 255 }),
}, (table) => [
	index("idx_storage_locations_active_name").using("btree", table.isActive.asc().nullsLast().op("text_ops"), table.locationName.asc().nullsLast().op("text_ops")),
	unique("storage_locations_location_name_unique").on(table.locationName),
]);

export const productWarehouseStocks = pgTable("product_warehouse_stocks", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	productId: uuid("product_id").notNull(),
	warehouseId: uuid("warehouse_id").notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	openingStock: numeric("opening_stock", { precision: 15, scale:  2 }).default('0').notNull(),
	openingStockValue: numeric("opening_stock_value", { precision: 15, scale:  2 }).default('0').notNull(),
	accountingStock: numeric("accounting_stock", { precision: 15, scale:  2 }).default('0').notNull(),
	physicalStock: numeric("physical_stock", { precision: 15, scale:  2 }).default('0').notNull(),
	committedStock: numeric("committed_stock", { precision: 15, scale:  2 }).default('0').notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_product_warehouse_stocks_org_outlet").using("btree", table.orgId.asc().nullsLast().op("uuid_ops"), table.outletId.asc().nullsLast().op("uuid_ops")),
	index("idx_product_warehouse_stocks_product").using("btree", table.productId.asc().nullsLast().op("uuid_ops")),
	index("idx_product_warehouse_stocks_warehouse").using("btree", table.warehouseId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "product_warehouse_stocks_product_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.warehouseId],
			foreignColumns: [warehouses.id],
			name: "product_warehouse_stocks_warehouse_id_fkey"
		}).onDelete("cascade"),
	unique("product_warehouse_stocks_unique_product_warehouse").on(table.productId, table.warehouseId),
]);

export const hsnSacCodes = pgTable("hsn_sac_codes", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	type: hsnSacType().notNull(),
	code: varchar({ length: 15 }).notNull(),
	description: text().notNull(),
}, (table) => [
	index("idx_hsn_sac_code").using("btree", table.code.asc().nullsLast().op("text_ops")),
	index("idx_hsn_sac_type").using("btree", table.type.asc().nullsLast().op("enum_ops")),
	unique("hsn_sac_codes_code_key").on(table.code),
]);

export const compositeItems = pgTable("composite_items", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	type: compositeType().notNull(),
	productName: varchar("product_name", { length: 255 }).notNull(),
	sku: varchar({ length: 100 }),
	unitId: uuid("unit_id").notNull(),
	categoryId: uuid("category_id"),
	isReturnable: boolean("is_returnable").default(false),
	pushToEcommerce: boolean("push_to_ecommerce").default(false),
	hsnCode: varchar("hsn_code", { length: 50 }),
	taxPreference: taxPreference("tax_preference"),
	intraStateTaxId: uuid("intra_state_tax_id"),
	interStateTaxId: uuid("inter_state_tax_id"),
	primaryImageUrl: text("primary_image_url"),
	imageUrls: text("image_urls"),
	sellingPrice: numeric("selling_price", { precision: 15, scale:  2 }),
	sellingPriceCurrency: varchar("selling_price_currency", { length: 10 }).default('INR'),
	ptr: numeric({ precision: 15, scale:  2 }),
	salesAccountId: uuid("sales_account_id"),
	salesDescription: text("sales_description"),
	costPrice: numeric("cost_price", { precision: 15, scale:  2 }),
	purchaseAccountId: uuid("purchase_account_id"),
	preferredVendorId: uuid("preferred_vendor_id"),
	purchaseDescription: text("purchase_description"),
	length: numeric({ precision: 10, scale:  2 }),
	width: numeric({ precision: 10, scale:  2 }),
	height: numeric({ precision: 10, scale:  2 }),
	dimensionUnit: varchar("dimension_unit", { length: 10 }).default('cm'),
	weight: numeric({ precision: 10, scale:  2 }),
	weightUnit: varchar("weight_unit", { length: 10 }).default('kg'),
	manufacturerId: uuid("manufacturer_id"),
	brandId: uuid("brand_id"),
	mpn: varchar({ length: 100 }),
	upc: varchar({ length: 20 }),
	isbn: varchar({ length: 20 }),
	ean: varchar({ length: 20 }),
	isTrackInventory: boolean("is_track_inventory").default(true),
	trackBatches: boolean("track_batches").default(false),
	trackSerialNumber: boolean("track_serial_number").default(false),
	inventoryAccountId: uuid("inventory_account_id"),
	inventoryValuationMethod: inventoryValuationMethod("inventory_valuation_method"),
	reorderPoint: integer("reorder_point").default(0),
	reorderTermId: uuid("reorder_term_id"),
	isActive: boolean("is_active").default(true),
	isLock: boolean("is_lock").default(false),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	createdById: uuid("created_by_id"),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedById: uuid("updated_by_id"),
}, (table) => [
	foreignKey({
			columns: [table.brandId],
			foreignColumns: [brands.id],
			name: "composite_items_brand_id_fkey"
		}),
	foreignKey({
			columns: [table.categoryId],
			foreignColumns: [categories.id],
			name: "composite_items_category_id_fkey"
		}),
	foreignKey({
			columns: [table.interStateTaxId],
			foreignColumns: [associateTaxes.id],
			name: "composite_items_inter_state_tax_id_fkey"
		}),
	foreignKey({
			columns: [table.intraStateTaxId],
			foreignColumns: [associateTaxes.id],
			name: "composite_items_intra_state_tax_id_fkey"
		}),
	foreignKey({
			columns: [table.inventoryAccountId],
			foreignColumns: [accounts.id],
			name: "composite_items_inventory_account_id_fkey"
		}),
	foreignKey({
			columns: [table.manufacturerId],
			foreignColumns: [manufacturers.id],
			name: "composite_items_manufacturer_id_fkey"
		}),
	foreignKey({
			columns: [table.purchaseAccountId],
			foreignColumns: [accounts.id],
			name: "composite_items_purchase_account_id_fkey"
		}),
	foreignKey({
			columns: [table.reorderTermId],
			foreignColumns: [reorderTerms.id],
			name: "composite_items_reorder_term_id_fkey"
		}),
	foreignKey({
			columns: [table.salesAccountId],
			foreignColumns: [accounts.id],
			name: "composite_items_sales_account_id_fkey"
		}),
	foreignKey({
			columns: [table.unitId],
			foreignColumns: [units.id],
			name: "composite_items_unit_id_fkey"
		}),
	unique("composite_items_sku_key").on(table.sku),
]);

export const priceListItems = pgTable("price_list_items", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	priceListId: uuid("price_list_id").notNull(),
	productId: uuid("product_id").notNull(),
	customRate: numeric("custom_rate", { precision: 15, scale:  2 }),
	discountPercentage: numeric("discount_percentage", { precision: 5, scale:  2 }),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_price_list_items_price_list").using("btree", table.priceListId.asc().nullsLast().op("uuid_ops")),
	index("idx_price_list_items_product").using("btree", table.productId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.priceListId],
			foreignColumns: [priceLists.id],
			name: "price_list_items_price_list_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "price_list_items_product_id_fkey"
		}).onDelete("cascade"),
	unique("price_list_items_price_list_id_product_id_key").on(table.priceListId, table.productId),
]);

export const itemVendorMappings = pgTable("item_vendor_mappings", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	vendorId: uuid("vendor_id").notNull(),
	itemId: uuid("item_id").notNull(),
	mappingName: varchar("mapping_name", { length: 255 }).notNull(),
	vendorProductCode: varchar("vendor_product_code", { length: 255 }),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.itemId],
			foreignColumns: [products.id],
			name: "item_vendor_mappings_item_id_fkey"
		}).onDelete("cascade"),
]);

export const priceListVolumeRanges = pgTable("price_list_volume_ranges", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	priceListItemId: uuid("price_list_item_id").notNull(),
	startQuantity: numeric("start_quantity", { precision: 15, scale:  2 }).notNull(),
	endQuantity: numeric("end_quantity", { precision: 15, scale:  2 }),
	rate: numeric({ precision: 15, scale:  2 }).notNull(),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_price_list_volume_ranges_item").using("btree", table.priceListItemId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.priceListItemId],
			foreignColumns: [priceListItems.id],
			name: "price_list_volume_ranges_price_list_item_id_fkey"
		}).onDelete("cascade"),
]);

export const customerContactPersons = pgTable("customer_contact_persons", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	customerId: uuid("customer_id").notNull(),
	salutation: varchar({ length: 10 }),
	firstName: varchar("first_name", { length: 100 }),
	lastName: varchar("last_name", { length: 100 }),
	email: varchar({ length: 255 }),
	workPhone: varchar("work_phone", { length: 20 }),
	mobilePhone: varchar("mobile_phone", { length: 20 }),
	displayOrder: integer("display_order").default(0),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_contact_persons_customer_id").using("btree", table.customerId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.customerId],
			foreignColumns: [customers.id],
			name: "customer_contact_persons_customer_id_fkey"
		}).onDelete("cascade"),
]);

export const customers = pgTable("customers", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	displayName: varchar("display_name", { length: 255 }).notNull(),
	customerType: varchar("customer_type", { length: 50 }).default('Business'),
	salutation: varchar({ length: 20 }),
	firstName: varchar("first_name", { length: 255 }),
	lastName: varchar("last_name", { length: 255 }),
	companyName: varchar("company_name", { length: 255 }),
	email: varchar({ length: 255 }),
	phone: varchar({ length: 50 }),
	mobilePhone: varchar("mobile_phone", { length: 50 }),
	gstin: varchar({ length: 50 }),
	pan: varchar({ length: 50 }),
	paymentTerms: varchar("payment_terms", { length: 100 }),
	billingAddress: text("billing_address"),
	shippingAddress: text("shipping_address"),
	isActive: boolean("is_active").default(true),
	receivables: numeric({ precision: 15, scale:  2 }).default('0.00'),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	customerNumber: varchar("customer_number", { length: 50 }),
	designation: varchar({ length: 100 }),
	department: varchar({ length: 100 }),
	businessType: varchar("business_type", { length: 50 }),
	customerLanguage: varchar("customer_language", { length: 50 }).default('English'),
	dateOfBirth: date("date_of_birth"),
	age: integer(),
	gender: varchar({ length: 20 }),
	placeOfCustomer: varchar("place_of_customer", { length: 255 }),
	privilegeCardNumber: varchar("privilege_card_number", { length: 100 }),
	parentCustomerId: uuid("parent_customer_id"),
	taxPreference: varchar("tax_preference", { length: 100 }),
	exemptionReason: text("exemption_reason"),
	drugLicenceType: varchar("drug_licence_type", { length: 50 }),
	drugLicense20: varchar("drug_license_20", { length: 100 }),
	drugLicense21: varchar("drug_license_21", { length: 100 }),
	drugLicense20B: varchar("drug_license_20b", { length: 100 }),
	drugLicense21B: varchar("drug_license_21b", { length: 100 }),
	fssai: varchar({ length: 100 }),
	msmeRegistrationType: varchar("msme_registration_type", { length: 50 }),
	msmeNumber: varchar("msme_number", { length: 100 }),
	drugLicense20DocUrl: text("drug_license_20_doc_url"),
	drugLicense21DocUrl: text("drug_license_21_doc_url"),
	drugLicense20BDocUrl: text("drug_license_20b_doc_url"),
	drugLicense21BDocUrl: text("drug_license_21b_doc_url"),
	fssaiDocUrl: text("fssai_doc_url"),
	msmeDocUrl: text("msme_doc_url"),
	openingBalance: numeric("opening_balance", { precision: 15, scale:  2 }).default('0'),
	creditLimit: numeric("credit_limit", { precision: 15, scale:  2 }),
	enablePortal: boolean("enable_portal").default(false),
	facebookHandle: varchar("facebook_handle", { length: 255 }),
	twitterHandle: varchar("twitter_handle", { length: 255 }),
	whatsappNumber: varchar("whatsapp_number", { length: 20 }),
	isRecurring: boolean("is_recurring").default(false),
	gstTreatment: varchar("gst_treatment", { length: 50 }),
	placeOfSupply: varchar("place_of_supply", { length: 100 }),
	website: varchar({ length: 255 }),
	priceListId: uuid("price_list_id"),
	receivableBalance: numeric("receivable_balance", { precision: 15, scale:  2 }).default('0'),
	billingAddressStreet1: varchar("billing_address_street1", { length: 255 }),
	billingAddressStreet2: varchar("billing_address_street2", { length: 255 }),
	billingAddressCity: varchar("billing_address_city", { length: 100 }),
	billingAddressZip: varchar("billing_address_zip", { length: 20 }),
	billingAddressPhone: varchar("billing_address_phone", { length: 50 }),
	shippingAddressStreet1: varchar("shipping_address_street1", { length: 255 }),
	shippingAddressStreet2: varchar("shipping_address_street2", { length: 255 }),
	shippingAddressCity: varchar("shipping_address_city", { length: 100 }),
	shippingAddressZip: varchar("shipping_address_zip", { length: 20 }),
	shippingAddressPhone: varchar("shipping_address_phone", { length: 50 }),
	remarks: text(),
	status: varchar({ length: 20 }).default('active'),
	documentUrls: text("document_urls"),
	isDrugRegistered: boolean("is_drug_registered"),
	isFssaiRegistered: boolean("is_fssai_registered"),
	isMsmeRegistered: boolean("is_msme_registered"),
	currencyId: uuid("currency_id"),
	billingAddressStateId: uuid("billing_address_state_id"),
	shippingAddressStateId: uuid("shipping_address_state_id"),
	billingAddressCountryId: uuid("billing_address_country_id"),
	shippingAddressCountryId: uuid("shipping_address_country_id"),
}, (table) => [
	foreignKey({
			columns: [table.billingAddressCountryId],
			foreignColumns: [countries.id],
			name: "customers_billing_address_country_id_fkey"
		}),
	foreignKey({
			columns: [table.billingAddressStateId],
			foreignColumns: [states.id],
			name: "customers_billing_address_state_id_states_id_fk"
		}),
	foreignKey({
			columns: [table.currencyId],
			foreignColumns: [currencies.id],
			name: "customers_currency_id_fkey"
		}),
	foreignKey({
			columns: [table.parentCustomerId],
			foreignColumns: [table.id],
			name: "customers_parent_customer_id_fkey"
		}),
	foreignKey({
			columns: [table.priceListId],
			foreignColumns: [priceLists.id],
			name: "customers_price_list_id_fkey"
		}),
	foreignKey({
			columns: [table.shippingAddressCountryId],
			foreignColumns: [countries.id],
			name: "customers_shipping_address_country_id_fkey"
		}),
	foreignKey({
			columns: [table.shippingAddressStateId],
			foreignColumns: [states.id],
			name: "customers_shipping_address_state_id_states_id_fk"
		}),
	unique("customers_customer_number_key").on(table.customerNumber),
]);

export const accountsFiscalYears = pgTable("accounts_fiscal_years", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	name: varchar({ length: 50 }).notNull(),
	startDate: date("start_date").notNull(),
	endDate: date("end_date").notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
});

export const outletInventory = pgTable("outlet_inventory", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	outletId: uuid("outlet_id").notNull(),
	productId: uuid("product_id").notNull(),
	currentStock: integer("current_stock").default(0).notNull(),
	reservedStock: integer("reserved_stock").default(0),
	availableStock: integer("available_stock").generatedAlwaysAs(sql`(current_stock - reserved_stock)`),
	batchNo: varchar("batch_no", { length: 100 }),
	expiryDate: date("expiry_date"),
	minStockLevel: integer("min_stock_level").default(0),
	maxStockLevel: integer("max_stock_level").default(0),
	lastStockUpdate: timestamp("last_stock_update", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_inventory_expiry").using("btree", table.expiryDate.asc().nullsLast().op("date_ops")),
	index("idx_inventory_outlet").using("btree", table.outletId.asc().nullsLast().op("uuid_ops")),
	index("idx_inventory_outlet_product").using("btree", table.outletId.asc().nullsLast().op("uuid_ops"), table.productId.asc().nullsLast().op("uuid_ops")),
	index("idx_inventory_product").using("btree", table.productId.asc().nullsLast().op("uuid_ops")),
	index("idx_outlet_inventory_outlet_product").using("btree", table.outletId.asc().nullsLast().op("uuid_ops"), table.productId.asc().nullsLast().op("uuid_ops")),
	unique("outlet_inventory_outlet_id_product_id_batch_no_key").on(table.outletId, table.productId, table.batchNo),
	check("outlet_inventory_current_stock_check", sql`current_stock >= 0`),
]);

export const uqc = pgTable("uqc", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	uqcCode: varchar("uqc_code", { length: 20 }).notNull(),
	description: varchar({ length: 255 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	unique("uqc_uqc_code_key").on(table.uqcCode),
]);

export const productWarehouseStockAdjustments = pgTable("product_warehouse_stock_adjustments", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	productId: uuid("product_id").notNull(),
	warehouseId: uuid("warehouse_id").notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	adjustmentType: text("adjustment_type").default('physical_count').notNull(),
	previousAccountingStock: numeric("previous_accounting_stock", { precision: 15, scale:  2 }).default('0').notNull(),
	previousPhysicalStock: numeric("previous_physical_stock", { precision: 15, scale:  2 }).default('0').notNull(),
	newPhysicalStock: numeric("new_physical_stock", { precision: 15, scale:  2 }).default('0').notNull(),
	committedStock: numeric("committed_stock", { precision: 15, scale:  2 }).default('0').notNull(),
	varianceQty: numeric("variance_qty", { precision: 15, scale:  2 }).default('0').notNull(),
	reason: text().notNull(),
	notes: text(),
	adjustedAt: timestamp("adjusted_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_product_warehouse_stock_adjustments_org_outlet").using("btree", table.orgId.asc().nullsLast().op("uuid_ops"), table.outletId.asc().nullsLast().op("uuid_ops")),
	index("idx_product_warehouse_stock_adjustments_product").using("btree", table.productId.asc().nullsLast().op("timestamptz_ops"), table.adjustedAt.desc().nullsFirst().op("timestamptz_ops")),
	index("idx_product_warehouse_stock_adjustments_warehouse").using("btree", table.warehouseId.asc().nullsLast().op("timestamptz_ops"), table.adjustedAt.desc().nullsFirst().op("uuid_ops")),
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "product_warehouse_stock_adjustments_product_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.warehouseId],
			foreignColumns: [warehouses.id],
			name: "product_warehouse_stock_adjustments_warehouse_fkey"
		}).onDelete("cascade"),
	check("product_warehouse_stock_adjustments_type_check", sql`adjustment_type = 'physical_count'::text`),
]);

export const productOutletInventorySettings = pgTable("product_outlet_inventory_settings", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	productId: uuid("product_id").notNull(),
	reorderPoint: integer("reorder_point").default(0).notNull(),
	reorderTermId: uuid("reorder_term_id"),
	isActive: boolean("is_active").default(true).notNull(),
	createdById: uuid("created_by_id"),
	updatedById: uuid("updated_by_id"),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_product_outlet_inventory_settings_org_outlet").using("btree", table.orgId.asc().nullsLast().op("uuid_ops"), table.outletId.asc().nullsLast().op("uuid_ops")),
	uniqueIndex("idx_product_outlet_inventory_settings_org_product_global").using("btree", table.orgId.asc().nullsLast().op("uuid_ops"), table.productId.asc().nullsLast().op("uuid_ops")).where(sql`(outlet_id IS NULL)`),
	uniqueIndex("idx_product_outlet_inventory_settings_outlet_product").using("btree", table.outletId.asc().nullsLast().op("uuid_ops"), table.productId.asc().nullsLast().op("uuid_ops")).where(sql`(outlet_id IS NOT NULL)`),
	index("idx_product_outlet_inventory_settings_product").using("btree", table.productId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "product_outlet_inventory_settings_product_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.reorderTermId],
			foreignColumns: [reorderTerms.id],
			name: "product_outlet_inventory_settings_reorder_term_fkey"
		}).onDelete("set null"),
	check("product_outlet_inventory_settings_reorder_point_check", sql`reorder_point >= 0`),
]);

export const compositeItemOutletInventorySettings = pgTable("composite_item_outlet_inventory_settings", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	outletId: uuid("outlet_id"),
	compositeItemId: uuid("composite_item_id").notNull(),
	reorderPoint: integer("reorder_point").default(0).notNull(),
	reorderTermId: uuid("reorder_term_id"),
	isActive: boolean("is_active").default(true).notNull(),
	createdById: uuid("created_by_id"),
	updatedById: uuid("updated_by_id"),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_composite_item_outlet_inventory_settings_item").using("btree", table.compositeItemId.asc().nullsLast().op("uuid_ops")),
	index("idx_composite_item_outlet_inventory_settings_org_outlet").using("btree", table.orgId.asc().nullsLast().op("uuid_ops"), table.outletId.asc().nullsLast().op("uuid_ops")),
	uniqueIndex("uq_composite_item_outlet_inventory_settings_org_item_global").using("btree", table.orgId.asc().nullsLast().op("uuid_ops"), table.compositeItemId.asc().nullsLast().op("uuid_ops")).where(sql`(outlet_id IS NULL)`),
	uniqueIndex("uq_composite_item_outlet_inventory_settings_outlet_item").using("btree", table.outletId.asc().nullsLast().op("uuid_ops"), table.compositeItemId.asc().nullsLast().op("uuid_ops")).where(sql`(outlet_id IS NOT NULL)`),
	foreignKey({
			columns: [table.compositeItemId],
			foreignColumns: [compositeItems.id],
			name: "composite_item_outlet_inventory_settings_composite_item_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.reorderTermId],
			foreignColumns: [reorderTerms.id],
			name: "composite_item_outlet_inventory_settings_reorder_term_fkey"
		}).onDelete("set null"),
	check("composite_item_outlet_inventory_settings_reorder_point_check", sql`reorder_point >= 0`),
]);

export const industries = pgTable("industries", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 255 }).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	sortOrder: smallint("sort_order").default(0).notNull(),
}, (table) => [
	unique("industries_name_key").on(table.name),
]);

export const timezones = pgTable("timezones", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 150 }).notNull(),
	tzdbName: varchar("tzdb_name", { length: 100 }).notNull(),
	utcOffset: varchar("utc_offset", { length: 10 }).notNull(),
	display: varchar({ length: 255 }).notNull(),
	countryId: uuid("country_id"),
	isActive: boolean("is_active").default(true).notNull(),
	sortOrder: smallint("sort_order").default(0).notNull(),
}, (table) => [
	foreignKey({
			columns: [table.countryId],
			foreignColumns: [countries.id],
			name: "timezones_country_id_fkey"
		}).onDelete("set null"),
	unique("timezones_name_key").on(table.name),
]);

export const companyIdLabels = pgTable("company_id_labels", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	label: varchar({ length: 50 }).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	sortOrder: smallint("sort_order").default(0).notNull(),
}, (table) => [
	unique("company_id_labels_label_key").on(table.label),
]);

export const organization = pgTable("organization", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 255 }).notNull(),
	slug: varchar({ length: 100 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
	stateId: uuid("state_id"),
	industry: varchar({ length: 255 }),
	logoUrl: text("logo_url"),
	baseCurrency: varchar("base_currency", { length: 10 }),
	fiscalYear: varchar("fiscal_year", { length: 50 }),
	timezone: varchar({ length: 100 }),
	dateFormat: varchar("date_format", { length: 50 }),
	dateSeparator: varchar("date_separator", { length: 5 }),
	companyIdLabel: varchar("company_id_label", { length: 50 }),
	companyIdValue: varchar("company_id_value", { length: 100 }),
	paymentStubAddress: text("payment_stub_address"),
	hasSeparatePaymentStubAddress: boolean("has_separate_payment_stub_address").default(false).notNull(),
	systemId: varchar("system_id", { length: 20 }).default(sql`(nextval('organization_system_id_seq'::regclass))::text`).notNull(),
}, (table) => [
	uniqueIndex("organization_system_id_key").using("btree", table.systemId.asc().nullsLast().op("text_ops")),
	foreignKey({
			columns: [table.stateId],
			foreignColumns: [states.id],
			name: "organization_state_id_fkey"
		}),
	unique("organization_slug_key").on(table.slug),
]);

export const settingsBranding = pgTable("settings_branding", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").notNull(),
	accentColor: varchar("accent_color", { length: 7 }).default('#22A95E').notNull(),
	themeMode: varchar("theme_mode", { length: 10 }).default('dark').notNull(),
	keepBranding: boolean("keep_branding").default(false).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_settings_branding_org_id").using("btree", table.orgId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.orgId],
			foreignColumns: [organization.id],
			name: "settings_branding_org_id_fkey"
		}).onDelete("cascade"),
	unique("settings_branding_org_id_key").on(table.orgId),
	pgPolicy("service_role_full_access", { as: "permissive", for: "all", to: ["public"], using: sql`true`, withCheck: sql`true`  }),
	check("settings_branding_theme_mode_check", sql`(theme_mode)::text = ANY ((ARRAY['dark'::character varying, 'light'::character varying])::text[])`),
]);

export const settingsOutlets = pgTable("settings_outlets", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").notNull(),
	name: varchar({ length: 255 }).notNull(),
	outletCode: varchar("outlet_code", { length: 50 }).notNull(),
	gstin: varchar({ length: 50 }),
	email: varchar({ length: 255 }),
	phone: varchar({ length: 50 }),
	address: text(),
	city: varchar({ length: 100 }),
	state: varchar({ length: 100 }),
	country: varchar({ length: 100 }),
	pincode: varchar({ length: 20 }),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_settings_outlets_org_id").using("btree", table.orgId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.orgId],
			foreignColumns: [organization.id],
			name: "settings_outlets_org_id_fkey"
		}).onDelete("cascade"),
	unique("settings_outlets_org_name_unique").on(table.orgId, table.name),
	pgPolicy("service_role_full_access", { as: "permissive", for: "all", to: ["public"], using: sql`true`, withCheck: sql`true`  }),
]);

export const settingsLocations = pgTable("settings_locations", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	outletId: uuid("outlet_id").notNull(),
	orgId: uuid("org_id").notNull(),
	locationType: locationType("location_type").default('business').notNull(),
	isPrimary: boolean("is_primary").default(false).notNull(),
	parentOutletId: uuid("parent_outlet_id"),
	logoUrl: text("logo_url"),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_settings_locations_org_id").using("btree", table.orgId.asc().nullsLast().op("uuid_ops")),
	index("idx_settings_locations_outlet_id").using("btree", table.outletId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.orgId],
			foreignColumns: [organization.id],
			name: "settings_locations_org_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.outletId],
			foreignColumns: [settingsOutlets.id],
			name: "settings_locations_outlet_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.parentOutletId],
			foreignColumns: [settingsOutlets.id],
			name: "settings_locations_parent_outlet_id_fkey"
		}).onDelete("set null"),
	unique("settings_locations_outlet_id_key").on(table.outletId),
	pgPolicy("service_role_full_access", { as: "permissive", for: "all", to: ["public"], using: sql`true`, withCheck: sql`true`  }),
]);

export const settingsTransactionSeries = pgTable("settings_transaction_series", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").notNull(),
	name: varchar({ length: 255 }).notNull(),
	modules: jsonb().default([]).notNull(),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_settings_ts_org_id").using("btree", table.orgId.asc().nullsLast().op("uuid_ops")),
]);

export const accountsManualJournalTagMappings = pgTable("accounts_manual_journal_tag_mappings", {
	manualJournalItemId: uuid("manual_journal_item_id").notNull(),
	reportingTagId: uuid("reporting_tag_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.manualJournalItemId],
			foreignColumns: [accountsManualJournalItems.id],
			name: "accounts_manual_journal_tag_mapping_manual_journal_item_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.reportingTagId],
			foreignColumns: [accountsReportingTags.id],
			name: "accounts_manual_journal_tag_mappings_reporting_tag_id_fkey"
		}).onDelete("cascade"),
	primaryKey({ columns: [table.manualJournalItemId, table.reportingTagId], name: "accounts_manual_journal_tag_mappings_pkey"}),
]);
export const auditLogsAll = pgView("audit_logs_all", {	id: uuid(),
	tableName: varchar("table_name", { length: 100 }),
	schemaName: text("schema_name"),
	recordId: uuid("record_id"),
	recordPk: text("record_pk"),
	action: varchar({ length: 10 }),
	oldValues: jsonb("old_values"),
	newValues: jsonb("new_values"),
	userId: uuid("user_id"),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }),
	orgId: uuid("org_id"),
	outletId: uuid("outlet_id"),
	actorName: text("actor_name"),
	changedColumns: text("changed_columns"),
	// You can use { mode: "bigint" } if numbers are exceeding js number limitations
	txid: bigint({ mode: "number" }),
	source: text(),
	moduleName: text("module_name"),
	requestId: text("request_id"),
	archivedAt: timestamp("archived_at", { withTimezone: true, mode: 'string' }),
}).as(sql`SELECT audit_logs.id, audit_logs.table_name, audit_logs.schema_name, audit_logs.record_id, audit_logs.record_pk, audit_logs.action, audit_logs.old_values, audit_logs.new_values, audit_logs.user_id, audit_logs.created_at, audit_logs.org_id, audit_logs.outlet_id, audit_logs.actor_name, audit_logs.changed_columns, audit_logs.txid, audit_logs.source, audit_logs.module_name, audit_logs.request_id, NULL::timestamp with time zone AS archived_at FROM audit_logs UNION ALL SELECT audit_logs_archive.id, audit_logs_archive.table_name, audit_logs_archive.schema_name, audit_logs_archive.record_id, audit_logs_archive.record_pk, audit_logs_archive.action, audit_logs_archive.old_values, audit_logs_archive.new_values, audit_logs_archive.user_id, audit_logs_archive.created_at, audit_logs_archive.org_id, audit_logs_archive.outlet_id, audit_logs_archive.actor_name, audit_logs_archive.changed_columns, audit_logs_archive.txid, audit_logs_archive.source, audit_logs_archive.module_name, audit_logs_archive.request_id, audit_logs_archive.archived_at FROM audit_logs_archive`);
