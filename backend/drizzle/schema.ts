import { pgTable, foreignKey, unique, uuid, varchar, date, boolean, timestamp, numeric, index, text, jsonb, integer, pgPolicy, check, smallint, uniqueIndex, bigint, type AnyPgColumn, primaryKey, pgView, pgSequence, pgEnum } from "drizzle-orm/pg-core"
import { sql } from "drizzle-orm"

export const accountGroupEnum = pgEnum("account_group_enum", ['Assets', 'Liabilities', 'Equity', 'Income', 'Expenses'])
export const accountType = pgEnum("account_type", ['sales', 'purchase', 'inventory', 'expense', 'asset'])
export const accountTypeEnum = pgEnum("account_type_enum", ['Bank', 'Cash', 'Accounts Receivable', 'Stock', 'Payment Clearing Account', 'Other Current Asset', 'Fixed Asset', 'Non Current Asset', 'Intangible Asset', 'Deferred Tax Asset', 'Other Asset', 'Credit Card', 'Accounts Payable', 'Other Current Liability', 'Overseas Tax Payable', 'Non Current Liability', 'Deferred Tax Liability', 'Other Liability', 'Equity', 'Income', 'Other Income', 'Cost Of Goods Sold', 'Expense', 'Other Expense'])
export const accountsContactType = pgEnum("accounts_contact_type", ['customer', 'vendor'])
export const accountsJournalTemplateType = pgEnum("accounts_journal_template_type", ['debit', 'credit'])
export const accountsManualJournalStatus = pgEnum("accounts_manual_journal_status", ['draft', 'published'])
export const accountsReportingMethod = pgEnum("accounts_reporting_method", ['accrual_and_cash', 'accrual_only', 'cash_only'])
export const adjustmentMode = pgEnum("adjustment_mode", ['quantity', 'value'])
export const branchType = pgEnum("branch_type", ['FOCO', 'COCO', 'FICO', 'FOFO', 'WAREHOUSE'])
export const challanType = pgEnum("challan_type", ['supply', 'job_work', 'other'])
export const compositeType = pgEnum("composite_type", ['assembly', 'kit'])
export const hsnSacType = pgEnum("hsn_sac_type", ['HSN', 'SAC'])
export const inventoryValuationMethod = pgEnum("inventory_valuation_method", ['FIFO', 'LIFO', 'Weighted Average', 'Specific Identification', 'FEFO'])
export const locationType = pgEnum("location_type", ['business', 'warehouse'])
export const productType = pgEnum("product_type", ['goods', 'service'])
export const status = pgEnum("status", ['draft', 'active', 'inactive', 'sent', 'paid', 'void', 'open', 'delivered', 'invoiced', 'returned', 'assembled', 'not_shipped', 'shipped'])
export const taxPreference = pgEnum("tax_preference", ['taxable', 'non-taxable', 'exempt'])
export const taxType = pgEnum("tax_type", ['IGST', 'CGST', 'SGST'])
export const unitType = pgEnum("unit_type", ['count', 'weight', 'volume', 'length', 'time', 'temperature', 'speed', 'area', 'energy', 'pressure', 'digital_storage'])
export const vendorType = pgEnum("vendor_type", ['manufacturer', 'distributor', 'wholesaler'])

export const organizationSystemIdSeq = pgSequence("organization_system_id_seq", {  startWith: "60000000000", increment: "1", minValue: "1", maxValue: "9223372036854775807", cache: "1", cycle: false })
export const branchesSystemIdSeq = pgSequence("branches_system_id_seq", {  startWith: "60000000000", increment: "1", minValue: "1", maxValue: "9223372036854775807", cache: "1", cycle: false })

export const batchMaster = pgTable("batch_master", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	productId: uuid("product_id"),
	batchNo: varchar("batch_no", { length: 100 }).notNull(),
	expiryDate: date("expiry_date").notNull(),
	unitPack: varchar("unit_pack"),
	isManufactureDetails: boolean("is_manufacture_details").default(false),
	manufactureBatchNumber: varchar("manufacture_batch_number", { length: 100 }),
	manufactureExp: date("manufacture_exp"),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	createdByEntityId: uuid("created_by_entity_id"),
	sourceType: varchar("source_type", { length: 30 }),
}, (table) => [
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "batches_product_id_fkey"
		}).onDelete("cascade"),
	unique("unique_product_batch").on(table.productId, table.batchNo),
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

export const purchaseReceives = pgTable("purchase_receives", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	purchaseReceiveNumber: varchar("purchase_receive_number").notNull(),
	receivedDate: date("received_date").notNull(),
	vendorName: varchar("vendor_name"),
	purchaseOrderId: uuid("purchase_order_id"),
	purchaseOrderNumber: varchar("purchase_order_number"),
	warehouseId: uuid("warehouse_id"),
	transactionBinId: uuid("transaction_bin_id"),
	transactionBinLabel: varchar("transaction_bin_label"),
	status: varchar().default('draft').notNull(),
	notes: text(),
	entityId: uuid("entity_id").notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_purchase_receives_entity_id").using("btree", table.entityId.asc().nullsLast().op("uuid_ops")),
	index("idx_purchase_receives_purchase_order_id").using("btree", table.purchaseOrderId.asc().nullsLast().op("uuid_ops")),
	index("idx_purchase_receives_warehouse_id").using("btree", table.warehouseId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "purchase_receives_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.purchaseOrderId],
			foreignColumns: [purchaseOrders.id],
			name: "purchase_receives_purchase_order_id_fkey"
		}),
	foreignKey({
			columns: [table.transactionBinId],
			foreignColumns: [binMaster.id],
			name: "purchase_receives_transaction_bin_id_fkey"
		}),
	foreignKey({
			columns: [table.warehouseId],
			foreignColumns: [warehouses.id],
			name: "purchase_receives_warehouse_id_fkey"
		}),
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

export const taxGroupRates = pgTable("tax_group_rates", {
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
			foreignColumns: [taxRates.id],
			name: "tax_group_taxes_tax_id_fkey"
		}).onDelete("cascade"),
]);

export const batchStockLayers = pgTable("batch_stock_layers", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	batchId: uuid("batch_id").notNull(),
	productId: uuid("product_id").notNull(),
	entityId: uuid("entity_id").notNull(),
	warehouseId: uuid("warehouse_id").notNull(),
	binId: uuid("bin_id").notNull(),
	vendorId: uuid("vendor_id"),
	purchaseRate: numeric("purchase_rate", { precision: 15, scale:  2 }).default('0').notNull(),
	mrp: numeric({ precision: 15, scale:  2 }).default('0').notNull(),
	qty: numeric({ precision: 15, scale:  3 }).default('0').notNull(),
	focQty: numeric("foc_qty", { precision: 15, scale:  3 }).default('0'),
	refId: uuid("ref_id"),
	refType: varchar("ref_type", { length: 30 }).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_batch_stock_layers_bin_id").using("btree", table.binId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "batch_stock_layers_product_id_fkey"
		}),
	foreignKey({
			columns: [table.batchId],
			foreignColumns: [batchMaster.id],
			name: "fk_batch"
		}).onDelete("cascade"),
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

export const drugStrengths = pgTable("drug_strengths", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	strengthName: varchar("strength_name", { length: 100 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_strengths_active_name").using("btree", table.isActive.asc().nullsLast().op("bool_ops"), table.strengthName.asc().nullsLast().op("text_ops")),
	index("strengths_is_active_idx").using("btree", table.isActive.asc().nullsLast().op("bool_ops")),
	unique("strengths_strength_name_key").on(table.strengthName),
]);

export const transactionLocks = pgTable("transaction_locks", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	moduleName: varchar("module_name", { length: 100 }).notNull(),
	lockDate: timestamp("lock_date", { mode: 'string' }).notNull(),
	reason: text(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "transaction_locks_entity_id_fkey"
		}),
	unique("idx_org_module_lock").on(table.orgId, table.moduleName),
]);

export const purchaseReceiveItems = pgTable("purchase_receive_items", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	purchaseReceiveId: uuid("purchase_receive_id").notNull(),
	itemId: uuid("item_id"),
	itemName: varchar("item_name").notNull(),
	description: text(),
	ordered: numeric().default('0').notNull(),
	received: numeric().default('0').notNull(),
	inTransit: numeric("in_transit").default('0').notNull(),
	quantityToReceive: numeric("quantity_to_receive").default('0').notNull(),
	warehouseId: uuid("warehouse_id"),
	binId: uuid("bin_id"),
	binLabel: varchar("bin_label"),
	entityId: uuid("entity_id").notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_purchase_receive_items_entity_id").using("btree", table.entityId.asc().nullsLast().op("uuid_ops")),
	index("idx_purchase_receive_items_item_id").using("btree", table.itemId.asc().nullsLast().op("uuid_ops")),
	index("idx_purchase_receive_items_receive_id").using("btree", table.purchaseReceiveId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.binId],
			foreignColumns: [binMaster.id],
			name: "purchase_receive_items_bin_id_fkey"
		}),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "purchase_receive_items_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.itemId],
			foreignColumns: [products.id],
			name: "purchase_receive_items_item_id_fkey"
		}),
	foreignKey({
			columns: [table.purchaseReceiveId],
			foreignColumns: [purchaseReceives.id],
			name: "purchase_receive_items_purchase_receive_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.warehouseId],
			foreignColumns: [warehouses.id],
			name: "purchase_receive_items_warehouse_id_fkey"
		}),
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
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.customerId],
			foreignColumns: [customers.id],
			name: "sales_payment_links_customer_id_customers_id_fk"
		}),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "sales_payment_links_entity_id_fkey"
		}),
]);

export const purchaseOrderAttachments = pgTable("purchase_order_attachments", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	purchaseOrderId: uuid("purchase_order_id").notNull(),
	fileName: varchar("file_name", { length: 255 }).notNull(),
	filePath: text("file_path").notNull(),
	fileSize: integer("file_size"),
	fileType: varchar("file_type", { length: 50 }),
	uploadedAt: timestamp("uploaded_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	foreignKey({
			columns: [table.purchaseOrderId],
			foreignColumns: [purchaseOrders.id],
			name: "purchases_purchase_order_attachments_purchase_order_id_fkey"
		}).onDelete("cascade"),
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

export const purchaseReceiveItemBatches = pgTable("purchase_receive_item_batches", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	purchaseReceiveItemId: uuid("purchase_receive_item_id").notNull(),
	productId: uuid("product_id").notNull(),
	warehouseId: uuid("warehouse_id"),
	binId: uuid("bin_id"),
	binLabel: varchar("bin_label"),
	batchNo: varchar("batch_no").notNull(),
	unitPack: varchar("unit_pack"),
	mrp: numeric(),
	ptr: numeric(),
	quantity: numeric().default('0').notNull(),
	focQty: numeric("foc_qty").default('0').notNull(),
	manufactureBatchNumber: varchar("manufacture_batch_number"),
	manufactureDate: date("manufacture_date"),
	expiryDate: date("expiry_date").notNull(),
	isDamaged: boolean("is_damaged").default(false).notNull(),
	damagedQty: numeric("damaged_qty").default('0').notNull(),
	entityId: uuid("entity_id").notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_pr_item_batches_batch_no").using("btree", table.batchNo.asc().nullsLast().op("text_ops")),
	index("idx_pr_item_batches_entity_id").using("btree", table.entityId.asc().nullsLast().op("uuid_ops")),
	index("idx_pr_item_batches_item_id").using("btree", table.purchaseReceiveItemId.asc().nullsLast().op("uuid_ops")),
	index("idx_pr_item_batches_product_id").using("btree", table.productId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.binId],
			foreignColumns: [binMaster.id],
			name: "purchase_receive_item_batches_bin_id_fkey"
		}),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "purchase_receive_item_batches_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "purchase_receive_item_batches_product_id_fkey"
		}),
	foreignKey({
			columns: [table.purchaseReceiveItemId],
			foreignColumns: [purchaseReceiveItems.id],
			name: "purchase_receive_item_batches_purchase_receive_item_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.warehouseId],
			foreignColumns: [warehouses.id],
			name: "purchase_receive_item_batches_warehouse_id_fkey"
		}),
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
			foreignColumns: [taxRates.id],
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
			foreignColumns: [drugSchedules.id],
			name: "products_schedule_of_drug_id_schedules_id_fk"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.storageId],
			foreignColumns: [storageConditions.id],
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

export const purchaseOrderItems = pgTable("purchase_order_items", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	purchaseOrderId: uuid("purchase_order_id").notNull(),
	sortOrder: integer("sort_order"),
	isHeader: boolean("is_header").default(false),
	headerText: text("header_text"),
	productId: uuid("product_id"),
	description: text(),
	accountId: uuid("account_id"),
	quantity: numeric({ precision: 15, scale:  2 }).default('0.00'),
	rate: numeric({ precision: 15, scale:  2 }).default('0.00'),
	taxId: uuid("tax_id"),
	itemTaxRate: numeric("item_tax_rate", { precision: 5, scale:  2 }).default('0.00'),
	taxAmount: numeric("tax_amount", { precision: 15, scale:  2 }).default('0.00'),
	discount: numeric({ precision: 15, scale:  2 }).default('0.00'),
	discountType: varchar("discount_type", { length: 20 }).default('percentage'),
	amount: numeric({ precision: 15, scale:  2 }).default('0.00'),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	entityId: uuid("entity_id"),
}, (table) => [
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "purchase_order_items_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.accountId],
			foreignColumns: [accounts.id],
			name: "purchases_purchase_order_items_account_id_fkey"
		}),
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "purchases_purchase_order_items_product_id_fkey"
		}),
	foreignKey({
			columns: [table.purchaseOrderId],
			foreignColumns: [purchaseOrders.id],
			name: "purchases_purchase_order_items_purchase_order_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.taxId],
			foreignColumns: [taxRates.id],
			name: "purchases_purchase_order_items_tax_id_fkey"
		}),
]);

export const taxRates = pgTable("tax_rates", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	taxName: varchar("tax_name", { length: 100 }).notNull(),
	taxRate: numeric("tax_rate", { precision: 5, scale:  2 }).notNull(),
	taxType: taxType("tax_type"),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	unique("tax_rates_tax_name_unique").on(table.taxName),
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
	entityId: uuid("entity_id").notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
}, (table) => [
	index("idx_accounts_active_system_name").using("btree", table.isActive.asc().nullsLast().op("text_ops"), table.systemAccountName.asc().nullsLast().op("bool_ops")),
	index("idx_accounts_active_user_name").using("btree", table.isActive.asc().nullsLast().op("text_ops"), table.userAccountName.asc().nullsLast().op("text_ops")),
	index("idx_accounts_group").using("btree", table.accountGroup.asc().nullsLast().op("enum_ops")),
	index("idx_accounts_lookup_name_trgm").using("gin", sql`lower((COALESCE(user_account_name, system_account_name))::text)`),
	index("idx_accounts_parent").using("btree", table.parentId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "accounts_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.parentId],
			foreignColumns: [table.id],
			name: "fk_accounts_parent"
		}).onDelete("cascade"),
	unique("accounts_system_name_unique").on(table.systemAccountName),
	unique("accounts_account_code_unique").on(table.accountCode),
	check("chk_account_group_type_match", sql`((account_group = 'Assets'::account_group_enum) AND (account_type = ANY (ARRAY['Bank'::account_type_enum, 'Cash'::account_type_enum, 'Accounts Receivable'::account_type_enum, 'Stock'::account_type_enum, 'Payment Clearing Account'::account_type_enum, 'Other Current Asset'::account_type_enum, 'Fixed Asset'::account_type_enum, 'Non Current Asset'::account_type_enum, 'Intangible Asset'::account_type_enum, 'Deferred Tax Asset'::account_type_enum, 'Other Asset'::account_type_enum]))) OR ((account_group = 'Liabilities'::account_group_enum) AND (account_type = ANY (ARRAY['Credit Card'::account_type_enum, 'Accounts Payable'::account_type_enum, 'Other Current Liability'::account_type_enum, 'Overseas Tax Payable'::account_type_enum, 'Non Current Liability'::account_type_enum, 'Deferred Tax Liability'::account_type_enum, 'Other Liability'::account_type_enum]))) OR ((account_group = 'Equity'::account_group_enum) AND (account_type = 'Equity'::account_type_enum)) OR ((account_group = 'Income'::account_group_enum) AND (account_type = ANY (ARRAY['Income'::account_type_enum, 'Other Income'::account_type_enum]))) OR ((account_group = 'Expenses'::account_group_enum) AND (account_type = ANY (ARRAY['Cost Of Goods Sold'::account_type_enum, 'Expense'::account_type_enum, 'Other Expense'::account_type_enum])))`),
]);

export const salesOrders = pgTable("sales_orders", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	customerId: uuid("customer_id").notNull(),
	transactionSeries: varchar("transaction_series", { length: 100 }),
	saleNumber: varchar("sale_number", { length: 100 }),
	reference: varchar({ length: 100 }),
	saleDate: timestamp("sale_date", { mode: 'string' }).defaultNow(),
	expectedShipmentDate: timestamp("expected_shipment_date", { mode: 'string' }),
	deliveryMethod: varchar("delivery_method", { length: 100 }),
	paymentTerms: varchar("payment_terms", { length: 100 }),
	paymentTermId: uuid("payment_term_id"),
	salespersonId: varchar("salesperson_id", { length: 255 }),
	salespersonName: varchar("salesperson_name", { length: 255 }),
	warehouseId: uuid("warehouse_id"),
	warehouseName: varchar("warehouse_name", { length: 255 }),
	priceListId: uuid("price_list_id"),
	placeOfSupply: varchar("place_of_supply", { length: 100 }),
	documentType: varchar("document_type", { length: 50 }).notNull(),
	status: varchar({ length: 50 }).default('Draft'),
	subTotal: numeric("sub_total", { precision: 15, scale:  2 }).default('0.00').notNull(),
	taxTotal: numeric("tax_total", { precision: 15, scale:  2 }).default('0.00').notNull(),
	discountTotal: numeric("discount_total", { precision: 15, scale:  2 }).default('0.00').notNull(),
	shippingCharges: numeric("shipping_charges", { precision: 15, scale:  2 }).default('0.00').notNull(),
	tdsTcsType: varchar("tds_tcs_type", { length: 10 }).default('TDS'),
	tdsTcsTaxId: uuid("tds_tcs_tax_id"),
	tdsTcsAmount: numeric("tds_tcs_amount", { precision: 15, scale:  2 }).default('0.00').notNull(),
	adjustment: numeric({ precision: 15, scale:  2 }).default('0.00').notNull(),
	roundOff: numeric("round_off", { precision: 15, scale:  2 }).default('0.00').notNull(),
	totalQuantity: numeric("total_quantity", { precision: 15, scale:  3 }).default('0.000').notNull(),
	total: numeric({ precision: 15, scale:  2 }).default('0.00').notNull(),
	currency: varchar({ length: 20 }).default('INR'),
	customerNotes: text("customer_notes"),
	termsAndConditions: text("terms_and_conditions"),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.customerId],
			foreignColumns: [customers.id],
			name: "sales_orders_customer_id_fkey"
		}),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "sales_orders_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.paymentTermId],
			foreignColumns: [paymentTerms.id],
			name: "sales_orders_payment_term_id_fkey"
		}),
	foreignKey({
			columns: [table.priceListId],
			foreignColumns: [priceLists.id],
			name: "sales_orders_price_list_id_fkey"
		}),
	foreignKey({
			columns: [table.tdsTcsTaxId],
			foreignColumns: [tdsRates.id],
			name: "sales_orders_tds_tcs_tax_id_fkey"
		}),
	foreignKey({
			columns: [table.warehouseId],
			foreignColumns: [warehouses.id],
			name: "sales_orders_warehouse_id_fkey"
		}),
	unique("sales_orders_sale_number_key").on(table.saleNumber),
	check("sales_orders_tds_tcs_type_check", sql`(tds_tcs_type)::text = ANY ((ARRAY['TDS'::character varying, 'TCS'::character varying])::text[])`),
]);

export const gstTreatments = pgTable("gst_treatments", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	code: varchar().notNull(),
	label: varchar().notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	unique("settings_gst_treatments_code_key").on(table.code),
]);

export const shipmentPreferences = pgTable("shipment_preferences", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 100 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	unique("shipment_preferences_name_key").on(table.name),
]);

export const priceLists = pgTable("price_lists", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 255 }).notNull(),
	description: text().default('),
	currency: varchar({ length: 20 }).default('INR'),
	pricingScheme: varchar("pricing_scheme", { length: 50 }).notNull(),
	details: text().default('),
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

export const drugLicenceTypes = pgTable("drug_licence_types", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	code: varchar().notNull(),
	label: varchar().notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	unique("settings_drug_licence_types_code_key").on(table.code),
]);

export const gstinRegistrationTypes = pgTable("gstin_registration_types", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	code: varchar().notNull(),
	label: varchar().notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	unique("settings_gstin_registration_types_code_key").on(table.code),
]);

export const salesOrderItems = pgTable("sales_order_items", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	salesOrderId: uuid("sales_order_id").notNull(),
	lineNo: integer("line_no").default(1).notNull(),
	productId: uuid("product_id").notNull(),
	description: text(),
	quantity: numeric({ precision: 15, scale:  3 }).default('0.000').notNull(),
	freeQuantity: numeric("free_quantity", { precision: 15, scale:  3 }).default('0.000').notNull(),
	rate: numeric({ precision: 15, scale:  2 }).default('0.00').notNull(),
	discountType: varchar("discount_type", { length: 10 }).default('%'),
	discountValue: numeric("discount_value", { precision: 15, scale:  2 }).default('0.00').notNull(),
	discountAmount: numeric("discount_amount", { precision: 15, scale:  2 }).default('0.00').notNull(),
	taxId: uuid("tax_id"),
	taxRate: numeric("tax_rate", { precision: 9, scale:  4 }).default('0.0000').notNull(),
	taxAmount: numeric("tax_amount", { precision: 15, scale:  2 }).default('0.00').notNull(),
	amount: numeric({ precision: 15, scale:  2 }).default('0.00').notNull(),
	mrp: numeric({ precision: 15, scale:  2 }).default('0.00').notNull(),
	batchId: uuid("batch_id"),
	warehouseId: uuid("warehouse_id"),
	lineMeta: jsonb("line_meta"),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	index("idx_sales_order_items_product_id").using("btree", table.productId.asc().nullsLast().op("uuid_ops")),
	index("idx_sales_order_items_sales_order_id").using("btree", table.salesOrderId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.batchId],
			foreignColumns: [batchMaster.id],
			name: "sales_order_items_batch_id_fkey"
		}),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "sales_order_items_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "sales_order_items_product_id_fkey"
		}),
	foreignKey({
			columns: [table.salesOrderId],
			foreignColumns: [salesOrders.id],
			name: "sales_order_items_sales_order_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.taxId],
			foreignColumns: [taxRates.id],
			name: "sales_order_items_tax_id_fkey"
		}),
	foreignKey({
			columns: [table.warehouseId],
			foreignColumns: [warehouses.id],
			name: "sales_order_items_warehouse_id_fkey"
		}),
	unique("sales_order_items_line_unique").on(table.salesOrderId, table.lineNo),
	check("sales_order_items_discount_type_check", sql`(discount_type)::text = ANY ((ARRAY['%'::character varying, 'value'::character varying])::text[])`),
]);

export const manualJournals = pgTable("manual_journals", {
	id: uuid().defaultRandom().primaryKey().notNull(),
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
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.fiscalYearId],
			foreignColumns: [fiscalYears.id],
			name: "accounts_manual_journals_fiscal_year_id_fkey"
		}),
	foreignKey({
			columns: [table.recurringJournalId],
			foreignColumns: [recurringJournals.id],
			name: "accounts_manual_journals_recurring_journal_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "manual_journals_entity_id_fkey"
		}),
	unique("accounts_manual_journals_journal_number_unique").on(table.journalNumber),
]);

export const journalNumberSettings = pgTable("journal_number_settings", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	autoGenerate: boolean("auto_generate").default(true),
	prefix: varchar({ length: 20 }),
	nextNumber: integer("next_number").default(1),
	isManualOverrideAllowed: boolean("is_manual_override_allowed").default(false),
	userId: uuid("user_id"),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "journal_number_settings_entity_id_fkey"
		}),
]);

export const journalTemplates = pgTable("journal_templates", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	templateName: varchar("template_name", { length: 255 }).notNull(),
	referenceNumber: varchar("reference_number", { length: 100 }),
	notes: text(),
	reportingMethod: accountsReportingMethod("reporting_method"),
	currencyCode: varchar("currency_code", { length: 10 }).default('INR'),
	isActive: boolean("is_active").default(true),
	enterAmount: boolean("enter_amount").default(false),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "journal_templates_entity_id_fkey"
		}),
]);

export const salesOrderAttachments = pgTable("sales_order_attachments", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	salesOrderId: uuid("sales_order_id").notNull(),
	fileName: varchar("file_name", { length: 255 }).notNull(),
	filePath: text("file_path").notNull(),
	fileSize: integer("file_size"),
	mimeType: varchar("mime_type", { length: 100 }),
	source: varchar({ length: 50 }).default('upload'),
	uploadedAt: timestamp("uploaded_at", { mode: 'string' }).defaultNow(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	index("idx_sales_order_attachments_sale_id").using("btree", table.salesOrderId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "sales_order_attachments_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.salesOrderId],
			foreignColumns: [salesOrders.id],
			name: "sales_order_attachments_sales_order_id_fkey"
		}).onDelete("cascade"),
]);

export const manualJournalAttachments = pgTable("manual_journal_attachments", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	manualJournalId: uuid("manual_journal_id").notNull(),
	fileName: varchar("file_name", { length: 255 }).notNull(),
	filePath: text("file_path").notNull(),
	fileSize: integer("file_size"),
	uploadedAt: timestamp("uploaded_at", { mode: 'string' }).defaultNow(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.manualJournalId],
			foreignColumns: [manualJournals.id],
			name: "accounts_manual_journal_attachments_manual_journal_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "manual_journal_attachments_entity_id_fkey"
		}),
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
	contactId: uuid("contact_id"),
	contactType: varchar("contact_type", { length: 50 }),
	entityId: uuid("entity_id").notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
}, (table) => [
	index("idx_account_transactions_contact_id").using("btree", table.contactId.asc().nullsLast().op("uuid_ops")),
	index("idx_account_transactions_contact_type").using("btree", table.contactType.asc().nullsLast().op("text_ops")),
	foreignKey({
			columns: [table.accountId],
			foreignColumns: [accounts.id],
			name: "account_transactions_account_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "account_transactions_entity_id_fkey"
		}),
]);

export const fiscalYearPresets = pgTable("fiscal_year_presets", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	code: varchar().notNull(),
	label: varchar().notNull(),
	startMonth: smallint("start_month").notNull(),
	endMonth: smallint("end_month").notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	unique("settings_fiscal_year_presets_code_key").on(table.code),
]);

export const dateFormat = pgTable("date_format", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	code: varchar().notNull(),
	formatPattern: varchar("format_pattern").notNull(),
	groupName: varchar("group_name").notNull(),
	label: varchar().notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	unique("settings_date_format_options_code_key").on(table.code),
]);

export const branchTransactionSeries = pgTable("branch_transaction_series", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	transactionSeriesId: uuid("transaction_series_id").notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	index("idx_settings_branch_transaction_series_series_id").using("btree", table.transactionSeriesId.asc().nullsLast().op("uuid_ops")),
	index("idx_settings_branch_transaction_series_transaction_series_id").using("btree", table.transactionSeriesId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "branch_transaction_series_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.transactionSeriesId],
			foreignColumns: [transactionSeries.id],
			name: "settings_branch_transaction_series_transaction_series_id_fkey"
		}).onDelete("cascade"),
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
			foreignColumns: [drugSchedules.id],
			name: "product_contents_schedule_id_fkey"
		}),
	foreignKey({
			columns: [table.strengthId],
			foreignColumns: [drugStrengths.id],
			name: "product_contents_strength_id_fkey"
		}),
]);

export const branchUsers = pgTable("branch_users", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	userId: uuid("user_id").notNull(),
	role: varchar({ length: 50 }),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	index("idx_settings_branch_users_user_id").using("btree", table.userId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "branch_users_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.userId],
			foreignColumns: [users.id],
			name: "settings_branch_users_user_id_fkey"
		}).onDelete("cascade"),
]);

export const lsgdWards = pgTable("lsgd_wards", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	localBodyId: uuid("local_body_id").notNull(),
	wardNo: integer("ward_no"),
	name: varchar({ length: 150 }).notNull(),
	code: varchar({ length: 50 }),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_settings_wards_local_body_id").using("btree", table.localBodyId.asc().nullsLast().op("uuid_ops")),
	uniqueIndex("settings_wards_local_body_code_key").using("btree", table.localBodyId.asc().nullsLast().op("text_ops"), table.code.asc().nullsLast().op("text_ops")).where(sql`(code IS NOT NULL)`),
	uniqueIndex("settings_wards_local_body_name_key").using("btree", table.localBodyId.asc().nullsLast().op("text_ops"), table.name.asc().nullsLast().op("text_ops")),
	uniqueIndex("settings_wards_local_body_ward_no_key").using("btree", table.localBodyId.asc().nullsLast().op("int4_ops"), table.wardNo.asc().nullsLast().op("uuid_ops")).where(sql`(ward_no IS NOT NULL)`),
	foreignKey({
			columns: [table.localBodyId],
			foreignColumns: [lsgdLocalBodies.id],
			name: "settings_wards_local_body_id_fkey"
		}).onDelete("cascade"),
]);

export const purchaseOrders = pgTable("purchase_orders", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orderNumber: varchar("order_number", { length: 100 }).notNull(),
	orderDate: date("order_date").notNull(),
	expectedDeliveryDate: date("expected_delivery_date"),
	referenceNumber: varchar("reference_number", { length: 100 }),
	vendorId: uuid("vendor_id").notNull(),
	paymentTermsId: uuid("payment_terms_id"),
	shipmentPreferenceId: uuid("shipment_preference_id"),
	deliveryType: varchar("delivery_type", { length: 20 }).default('warehouse').notNull(),
	deliveryWarehouseId: uuid("delivery_warehouse_id"),
	deliveryCustomerId: uuid("delivery_customer_id"),
	warehouseId: uuid("warehouse_id"),
	discountLevel: varchar("discount_level", { length: 20 }).default('transaction'),
	discount: numeric({ precision: 15, scale:  2 }).default('0.00'),
	discountType: varchar("discount_type", { length: 20 }).default('percentage'),
	totalQuantity: numeric("total_quantity", { precision: 15, scale:  2 }).default('0.00'),
	currency: varchar({ length: 20 }).default('INR'),
	subtotal: numeric({ precision: 15, scale:  2 }).default('0.00'),
	taxAmount: numeric("tax_amount", { precision: 15, scale:  2 }).default('0.00'),
	taxType: varchar("tax_type", { length: 20 }).default('exclusive'),
	tdsTcsType: varchar("tds_tcs_type", { length: 10 }).default('none'),
	tdsId: uuid("tds_id"),
	tdsTcsAmount: numeric("tds_tcs_amount", { precision: 15, scale:  2 }).default('0.00'),
	adjustment: numeric({ precision: 15, scale:  2 }).default('0.00'),
	total: numeric({ precision: 15, scale:  2 }).default('0.00'),
	status: varchar({ length: 50 }).default('Draft'),
	notes: text(),
	termsAndConditions: text("terms_and_conditions"),
	isReverseCharge: boolean("is_reverse_charge").default(false),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "purchase_orders_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.deliveryCustomerId],
			foreignColumns: [customers.id],
			name: "purchases_purchase_orders_delivery_customer_id_fkey"
		}),
	foreignKey({
			columns: [table.deliveryWarehouseId],
			foreignColumns: [warehouses.id],
			name: "purchases_purchase_orders_delivery_warehouse_id_fkey"
		}),
	foreignKey({
			columns: [table.paymentTermsId],
			foreignColumns: [paymentTerms.id],
			name: "purchases_purchase_orders_payment_terms_id_fkey"
		}),
	foreignKey({
			columns: [table.shipmentPreferenceId],
			foreignColumns: [shipmentPreferences.id],
			name: "purchases_purchase_orders_shipment_preference_id_fkey"
		}),
	foreignKey({
			columns: [table.tdsId],
			foreignColumns: [tdsRates.id],
			name: "purchases_purchase_orders_tds_id_fkey"
		}),
	foreignKey({
			columns: [table.vendorId],
			foreignColumns: [vendors.id],
			name: "purchases_purchase_orders_vendor_id_fkey"
		}),
	foreignKey({
			columns: [table.warehouseId],
			foreignColumns: [warehouses.id],
			name: "purchases_purchase_orders_warehouse_id_fkey"
		}).onDelete("set null"),
]);

export const dateSeparator = pgTable("date_separator", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	code: varchar().notNull(),
	separator: varchar().notNull(),
	label: varchar().notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	unique("settings_date_separator_options_code_key").on(table.code),
]);

export const recurringJournals = pgTable("recurring_journals", {
	id: uuid().defaultRandom().primaryKey().notNull(),
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
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "recurring_journals_entity_id_fkey"
		}),
]);

export const reorderTerms = pgTable("reorder_terms", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	termName: varchar("term_name", { length: 255 }).notNull(),
	description: text(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	quantity: integer().default(1).notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	index("idx_reorder_terms_active_name").using("btree", table.isActive.asc().nullsLast().op("text_ops"), table.termName.asc().nullsLast().op("text_ops")),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "reorder_terms_entity_id_fkey"
		}),
	check("reorder_terms_quantity_positive", sql`quantity > 0`),
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

export const vendors = pgTable("vendors", {
	id: uuid().defaultRandom().primaryKey().notNull(),
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
	billingAddressStreet: text("billing_address_street"),
	billingAddressPlace: text("billing_address_place"),
	billingCity: text("billing_city"),
	billingState: text("billing_state"),
	billingPincode: text("billing_pincode"),
	billingCountryRegion: text("billing_country_region"),
	billingPhone: text("billing_phone"),
	billingFax: text("billing_fax"),
	shippingAttention: text("shipping_attention"),
	shippingAddressStreet: text("shipping_address_street"),
	shippingAddressPlace: text("shipping_address_place"),
	shippingCity: text("shipping_city"),
	shippingState: text("shipping_state"),
	shippingPincode: text("shipping_pincode"),
	shippingCountryRegion: text("shipping_country_region"),
	shippingPhone: text("shipping_phone"),
	shippingFax: text("shipping_fax"),
	priceListId: uuid("price_list_id"),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	index("idx_vendors_active_display_name").using("btree", table.isActive.asc().nullsLast().op("bool_ops"), table.displayName.asc().nullsLast().op("text_ops")),
	index("idx_vendors_display_name_trgm").using("gin", sql`lower((display_name)::text)`),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "vendors_entity_id_fkey"
		}),
	unique("vendors_vendor_number_unique").on(table.vendorNumber),
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

export const lsgdDistricts = pgTable("lsgd_districts", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	stateId: uuid("state_id").notNull(),
	name: varchar({ length: 150 }).notNull(),
	code: varchar({ length: 50 }),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_settings_districts_state_id").using("btree", table.stateId.asc().nullsLast().op("uuid_ops")),
	uniqueIndex("settings_districts_state_id_code_key").using("btree", table.stateId.asc().nullsLast().op("uuid_ops"), table.code.asc().nullsLast().op("uuid_ops")).where(sql`(code IS NOT NULL)`),
	uniqueIndex("settings_districts_state_id_name_key").using("btree", table.stateId.asc().nullsLast().op("text_ops"), table.name.asc().nullsLast().op("text_ops")),
	foreignKey({
			columns: [table.stateId],
			foreignColumns: [states.id],
			name: "settings_districts_state_id_fkey"
		}).onDelete("cascade"),
]);

export const transactionSeriesModules = pgTable("transaction_series_modules", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	code: varchar().notNull(),
	label: varchar().notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	unique("settings_transaction_modules_code_key").on(table.code),
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
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	index("audit_logs_archive_action_created_at_idx").using("btree", table.action.asc().nullsLast().op("timestamptz_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	index("audit_logs_archive_org_id_created_at_idx").using("btree", table.orgId.asc().nullsLast().op("uuid_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	index("audit_logs_archive_table_name_record_id_idx").using("btree", table.tableName.asc().nullsLast().op("uuid_ops"), table.recordId.asc().nullsLast().op("uuid_ops")),
	index("audit_logs_archive_table_name_record_pk_idx").using("btree", table.tableName.asc().nullsLast().op("text_ops"), table.recordPk.asc().nullsLast().op("text_ops")),
	index("audit_logs_archive_user_id_created_at_idx").using("btree", table.userId.asc().nullsLast().op("uuid_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	index("idx_audit_logs_archive_org_created").using("btree", table.orgId.asc().nullsLast().op("timestamptz_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	index("idx_audit_logs_archive_request_id").using("btree", table.requestId.asc().nullsLast().op("text_ops")),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "audit_logs_archive_entity_id_fkey"
		}),
	pgPolicy("audit_logs_archive_read_all", { as: "permissive", for: "select", to: ["anon", "authenticated", "service_role"], using: sql`true` }),
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
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.customerId],
			foreignColumns: [customers.id],
			name: "sales_payments_customer_id_customers_id_fk"
		}),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "sales_payments_entity_id_fkey"
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
	actorName: text("actor_name").default('system').notNull(),
	schemaName: text("schema_name").default('public').notNull(),
	recordPk: text("record_pk"),
	changedColumns: text("changed_columns").array(),
	// You can use { mode: "bigint" } if numbers are exceeding js number limitations
	txid: bigint({ mode: "number" }).default(sql`txid_current()`).notNull(),
	source: text().default('system').notNull(),
	moduleName: text("module_name"),
	requestId: text("request_id"),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	index("idx_audit_logs_action_created").using("btree", table.action.asc().nullsLast().op("timestamptz_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	index("idx_audit_logs_org_created").using("btree", table.orgId.asc().nullsLast().op("timestamptz_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	index("idx_audit_logs_record_pk").using("btree", table.tableName.asc().nullsLast().op("text_ops"), table.recordPk.asc().nullsLast().op("text_ops")),
	index("idx_audit_logs_request_id").using("btree", table.requestId.asc().nullsLast().op("text_ops")),
	index("idx_audit_logs_schema_table_record").using("btree", table.schemaName.asc().nullsLast().op("uuid_ops"), table.tableName.asc().nullsLast().op("text_ops"), table.recordId.asc().nullsLast().op("uuid_ops")),
	index("idx_audit_logs_table_record").using("btree", table.tableName.asc().nullsLast().op("uuid_ops"), table.recordId.asc().nullsLast().op("uuid_ops")),
	index("idx_audit_logs_table_record_pk").using("btree", table.tableName.asc().nullsLast().op("text_ops"), table.recordPk.asc().nullsLast().op("text_ops")),
	index("idx_audit_logs_user_created").using("btree", table.userId.asc().nullsLast().op("timestamptz_ops"), table.createdAt.desc().nullsFirst().op("timestamptz_ops")),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "audit_logs_entity_id_fkey"
		}),
	pgPolicy("audit_logs_read_all", { as: "permissive", for: "select", to: ["anon", "authenticated", "service_role"], using: sql`true` }),
]);

export const drugSchedules = pgTable("drug_schedules", {
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

export const uqc = pgTable("uqc", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	uqcCode: varchar("uqc_code", { length: 20 }).notNull(),
	description: varchar({ length: 255 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	unique("uqc_uqc_code_key").on(table.uqcCode),
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

export const transactionSeriesRestartOptions = pgTable("transaction_series_restart_options", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	code: varchar().notNull(),
	label: varchar().notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	unique("settings_transaction_restart_options_code_key").on(table.code),
]);

export const recurringJournalItems = pgTable("recurring_journal_items", {
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
			foreignColumns: [recurringJournals.id],
			name: "accounts_recurring_journal_items_recur_journal_id_fkey"
		}).onDelete("cascade"),
]);

export const fiscalYears = pgTable("fiscal_years", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	name: varchar({ length: 50 }).notNull(),
	startDate: date("start_date").notNull(),
	endDate: date("end_date").notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "fiscal_years_entity_id_fkey"
		}),
]);

export const journalTemplateItems = pgTable("journal_template_items", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	templateId: uuid("template_id").notNull(),
	accountId: uuid("account_id").notNull(),
	description: text(),
	contactId: uuid("contact_id"),
	contactType: accountsContactType("contact_type"),
	type: accountsJournalTemplateType(),
	debit: numeric({ precision: 15, scale:  2 }).default('0.00'),
	credit: numeric({ precision: 15, scale:  2 }).default('0.00'),
	sortOrder: integer("sort_order"),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.accountId],
			foreignColumns: [accounts.id],
			name: "accounts_journal_template_items_account_id_fkey"
		}),
	foreignKey({
			columns: [table.templateId],
			foreignColumns: [journalTemplates.id],
			name: "accounts_journal_template_items_template_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "journal_template_items_entity_id_fkey"
		}),
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

export const transactionSeriesPlaceholders = pgTable("transaction_series_placeholders", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	token: varchar().notNull(),
	label: varchar().notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	unique("settings_transaction_prefix_placeholders_token_key").on(table.token),
]);

export const manualJournalItems = pgTable("manual_journal_items", {
	id: uuid().defaultRandom().primaryKey().notNull(),
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
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.accountId],
			foreignColumns: [accounts.id],
			name: "accounts_manual_journal_items_account_id_fkey"
		}),
	foreignKey({
			columns: [table.manualJournalId],
			foreignColumns: [manualJournals.id],
			name: "accounts_manual_journal_items_manual_journal_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "manual_journal_items_entity_id_fkey"
		}),
]);

export const storageConditions = pgTable("storage_conditions", {
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
			foreignColumns: [taxRates.id],
			name: "composite_items_inter_state_tax_id_fkey"
		}),
	foreignKey({
			columns: [table.intraStateTaxId],
			foreignColumns: [taxRates.id],
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

export const batchTransactions = pgTable("batch_transactions", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	batchId: uuid("batch_id").notNull(),
	layerId: uuid("layer_id"),
	productId: uuid("product_id").notNull(),
	entityId: uuid("entity_id").notNull(),
	warehouseId: uuid("warehouse_id").notNull(),
	binId: uuid("bin_id"),
	transType: varchar("trans_type", { length: 30 }).notNull(),
	refId: uuid("ref_id"),
	refNo: varchar("ref_no", { length: 50 }),
	qtyIn: numeric("qty_in", { precision: 15, scale:  3 }).default('0'),
	qtyOut: numeric("qty_out", { precision: 15, scale:  3 }).default('0'),
	rate: numeric({ precision: 15, scale:  2 }),
	transDate: timestamp("trans_date", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
});

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

export const companyIdLabels = pgTable("company_id_labels", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	label: varchar({ length: 50 }).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	sortOrder: smallint("sort_order").default(0).notNull(),
}, (table) => [
	unique("company_id_labels_label_key").on(table.label),
]);

export const industries = pgTable("industries", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 255 }).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	sortOrder: smallint("sort_order").default(0).notNull(),
}, (table) => [
	unique("industries_name_key").on(table.name),
]);

export const zoneMaster = pgTable("zone_master", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	entityId: uuid("entity_id").notNull(),
	warehouseId: uuid("warehouse_id").notNull(),
	zoneName: varchar("zone_name", { length: 100 }).notNull(),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_zone_master_entity_warehouse").using("btree", table.entityId.asc().nullsLast().op("uuid_ops"), table.warehouseId.asc().nullsLast().op("uuid_ops")),
	uniqueIndex("uq_zone_master_entity_warehouse_name").using("btree", sql`entity_id`, sql`warehouse_id`, sql`lower((zone_name)::text)`),
]);

export const productVendorMappings = pgTable("product_vendor_mappings", {
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

export const organisationBranchMaster = pgTable("organisation_branch_master", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 150 }).notNull(),
	type: varchar({ length: 20 }).notNull(),
	refId: uuid("ref_id").notNull(),
	parentId: uuid("parent_id"),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_organisation_branch_master_parent_id").using("btree", table.parentId.asc().nullsLast().op("uuid_ops")),
	index("idx_organisation_branch_master_type").using("btree", table.type.asc().nullsLast().op("text_ops")),
	unique("unique_entity").on(table.type, table.refId),
	unique("organisation_branch_master_ref_id_key").on(table.refId),
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
	billingAddressStreet: varchar("billing_address_street", { length: 255 }),
	billingAddressPlace: varchar("billing_address_place", { length: 255 }),
	billingAddressCity: varchar("billing_address_city", { length: 100 }),
	billingAddressZip: varchar("billing_address_zip", { length: 20 }),
	billingAddressPhone: varchar("billing_address_phone", { length: 50 }),
	shippingAddressStreet: varchar("shipping_address_street", { length: 255 }),
	shippingAddressPlace: varchar("shipping_address_place", { length: 255 }),
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
	entityId: uuid("entity_id").notNull(),
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
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "customers_entity_id_fkey"
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
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	index("idx_contact_persons_customer_id").using("btree", table.customerId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.customerId],
			foreignColumns: [customers.id],
			name: "customer_contact_persons_customer_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "customer_contact_persons_entity_id_fkey"
		}),
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

export const assembliesConstituencies = pgTable("assemblies_constituencies", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	districtId: uuid("district_id").notNull(),
	code: varchar({ length: 50 }),
	name: varchar({ length: 150 }).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_settings_assemblies_district_id").using("btree", table.districtId.asc().nullsLast().op("uuid_ops")),
	uniqueIndex("settings_assemblies_district_code_unique").using("btree", table.districtId.asc().nullsLast().op("text_ops"), table.code.asc().nullsLast().op("text_ops")).where(sql`(code IS NOT NULL)`),
	foreignKey({
			columns: [table.districtId],
			foreignColumns: [lsgdDistricts.id],
			name: "settings_assemblies_district_id_fkey"
		}).onDelete("cascade"),
	unique("settings_assemblies_district_name_unique").on(table.districtId, table.name),
]);

export const branding = pgTable("branding", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	accentColor: varchar("accent_color", { length: 7 }).default('#22A95E').notNull(),
	themeMode: varchar("theme_mode", { length: 10 }).default('dark').notNull(),
	keepBranding: boolean("keep_branding").default(false).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "branding_entity_id_fkey"
		}),
	pgPolicy("service_role_full_access", { as: "permissive", for: "all", to: ["public"], using: sql`true`, withCheck: sql`true`  }),
	check("settings_branding_theme_mode_check", sql`(theme_mode)::text = ANY ((ARRAY['dark'::character varying, 'light'::character varying])::text[])`),
]);

export const zoneLevels = pgTable("zone_levels", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	zoneId: uuid("zone_id").notNull(),
	levelNo: integer("level_no").notNull(),
	levelName: varchar("level_name", { length: 100 }),
	alias: varchar({ length: 50 }),
	delimiter: varchar({ length: 5 }).default('-'),
	total: integer().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_zone_levels_zone_level").using("btree", table.zoneId.asc().nullsLast().op("int4_ops"), table.levelNo.asc().nullsLast().op("int4_ops")),
	foreignKey({
			columns: [table.zoneId],
			foreignColumns: [zoneMaster.id],
			name: "fk_zone"
		}).onDelete("cascade"),
]);

export const businessTypes = pgTable("business_types", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	code: varchar().notNull(),
	label: varchar().notNull(),
	description: text().default(').notNull(),
	sortOrder: integer("sort_order").default(0).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	unique("settings_business_types_code_key").on(table.code),
]);

export const users = pgTable("users", {
	id: uuid().primaryKey().notNull(),
	email: varchar({ length: 255 }).notNull(),
	fullName: varchar("full_name", { length: 255 }).notNull(),
	role: varchar({ length: 50 }).default('user').notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	entityId: uuid("entity_id").notNull(),
	defaultWarehouseId: uuid("default_warehouse_id"),
}, (table) => [
	foreignKey({
			columns: [table.defaultWarehouseId],
			foreignColumns: [warehouses.id],
			name: "users_default_warehouse_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "users_entity_id_fkey"
		}),
	unique("users_email_key").on(table.email),
	pgPolicy("service_role_full_access", { as: "permissive", for: "all", to: ["public"], using: sql`true`, withCheck: sql`true`  }),
]);

export const binMaster = pgTable("bin_master", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	entityId: uuid("entity_id").notNull(),
	warehouseId: uuid("warehouse_id").notNull(),
	zoneId: uuid("zone_id").notNull(),
	binCode: varchar("bin_code", { length: 100 }).notNull(),
	levelPath: text("level_path"),
	binType: varchar("bin_type", { length: 20 }),
	isActive: boolean("is_active").default(true),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_bin_master_zone").using("btree", table.zoneId.asc().nullsLast().op("uuid_ops")),
	uniqueIndex("uq_bin_master_zone_code").using("btree", sql`zone_id`, sql`lower((bin_code)::text)`),
	foreignKey({
			columns: [table.zoneId],
			foreignColumns: [zoneMaster.id],
			name: "fk_zone"
		}),
]);

export const lsgdLocalBodies = pgTable("lsgd_local_bodies", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	districtId: uuid("district_id").notNull(),
	name: varchar({ length: 150 }).notNull(),
	code: varchar({ length: 50 }),
	bodyType: varchar("body_type", { length: 30 }).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_settings_local_bodies_district_id").using("btree", table.districtId.asc().nullsLast().op("uuid_ops")),
	uniqueIndex("settings_local_bodies_district_type_code_key").using("btree", table.districtId.asc().nullsLast().op("text_ops"), table.bodyType.asc().nullsLast().op("text_ops"), table.code.asc().nullsLast().op("uuid_ops")).where(sql`(code IS NOT NULL)`),
	uniqueIndex("settings_local_bodies_district_type_name_key").using("btree", table.districtId.asc().nullsLast().op("uuid_ops"), table.bodyType.asc().nullsLast().op("uuid_ops"), table.name.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.districtId],
			foreignColumns: [lsgdDistricts.id],
			name: "settings_local_bodies_district_id_fkey"
		}).onDelete("cascade"),
	check("settings_local_bodies_body_type_check", sql`(body_type)::text = ANY (ARRAY[('grama_panchayat'::character varying)::text, ('municipality'::character varying)::text, ('corporation'::character varying)::text, ('town_panchayat'::character varying)::text])`),
]);

export const transactionalSequences = pgTable("transactional_sequences", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	module: varchar().notNull(),
	prefix: varchar().default(').notNull(),
	suffix: varchar().default('),
	nextNumber: integer("next_number").default(1).notNull(),
	padding: integer().default(5).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	entityId: uuid("entity_id").notNull(),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_transactional_sequences_entity_id").using("btree", table.entityId.asc().nullsLast().op("uuid_ops")),
	index("idx_transactional_sequences_module").using("btree", table.module.asc().nullsLast().op("text_ops")),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "transactional_sequences_entity_id_fkey"
		}),
	unique("transactional_sequences_unique").on(table.module, table.entityId),
]);

export const roles = pgTable("roles", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	label: varchar({ length: 100 }).notNull(),
	description: text().default(').notNull(),
	permissions: jsonb().default({}).notNull(),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	uniqueIndex("roles_entity_id_label_unique").using("btree", sql`entity_id`, sql`lower((label)::text)`),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "roles_entity_id_fkey"
		}),
	pgPolicy("service_role_full_access", { as: "permissive", for: "all", to: ["public"], using: sql`true`, withCheck: sql`true`  }),
]);

export const transactionSeries = pgTable("transaction_series", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id"),
	name: varchar({ length: 255 }).notNull(),
	modules: jsonb().default([]).notNull(),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow(),
	code: varchar({ length: 50 }),
	branchCode: varchar("branch_code", { length: 50 }),
	warehouseCode: varchar("warehouse_code", { length: 50 }),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	index("idx_settings_transaction_series_branch_code").using("btree", table.branchCode.asc().nullsLast().op("text_ops")),
	index("idx_settings_transaction_series_org_id").using("btree", table.orgId.asc().nullsLast().op("uuid_ops")),
	index("idx_settings_transaction_series_warehouse_code").using("btree", table.warehouseCode.asc().nullsLast().op("text_ops")),
	index("idx_settings_ts_org_id").using("btree", table.orgId.asc().nullsLast().op("uuid_ops")),
	uniqueIndex("settings_transaction_series_org_code_key").using("btree", table.orgId.asc().nullsLast().op("uuid_ops"), table.code.asc().nullsLast().op("uuid_ops")).where(sql`(code IS NOT NULL)`),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "transaction_series_entity_id_fkey"
		}),
]);

export const userBranchAccess = pgTable("user_branch_access", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").notNull(),
	userId: uuid("user_id").notNull(),
	isDefaultBusiness: boolean("is_default_business").default(false).notNull(),
	isDefaultWarehouse: boolean("is_default_warehouse").default(false).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	index("idx_settings_user_location_access_org_user").using("btree", table.orgId.asc().nullsLast().op("uuid_ops"), table.userId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.orgId],
			foreignColumns: [organization.id],
			name: "settings_user_location_access_org_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "user_branch_access_entity_id_fkey"
		}),
	unique("user_branch_access_org_user_entity_unique").on(table.orgId, table.userId, table.entityId),
	pgPolicy("service_role_full_access", { as: "permissive", for: "all", to: ["public"], using: sql`true`, withCheck: sql`true`  }),
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
	systemId: varchar("system_id", { length: 20 }).default((nextval(\'organization_system_id_seq').notNull(),
	baseCurrencyDecimals: smallint("base_currency_decimals"),
	baseCurrencyFormat: varchar("base_currency_format", { length: 50 }),
	organizationLanguage: varchar("organization_language", { length: 50 }).default('English'),
	communicationLanguages: text("communication_languages").array().default(["RAY['English'::tex"]).notNull(),
	paymentStubDistrictId: uuid("payment_stub_district_id"),
	paymentStubLocalBodyId: uuid("payment_stub_local_body_id"),
	paymentStubWardId: uuid("payment_stub_ward_id"),
	isDrugRegistered: boolean("is_drug_registered").default(false).notNull(),
	drugLicenceType: varchar("drug_licence_type"),
	drugLicense20: varchar("drug_license_20"),
	drugLicense21: varchar("drug_license_21"),
	drugLicense20B: varchar("drug_license_20b"),
	drugLicense21B: varchar("drug_license_21b"),
	isFssaiRegistered: boolean("is_fssai_registered").default(false).notNull(),
	fssaiNumber: varchar("fssai_number"),
	isMsmeRegistered: boolean("is_msme_registered").default(false).notNull(),
	msmeRegistrationType: varchar("msme_registration_type"),
	msmeNumber: varchar("msme_number"),
	paymentStubAssemblyId: uuid("payment_stub_assembly_id"),
	attention: text(),
	street: text(),
	place: text(),
	city: varchar({ length: 100 }),
	pincode: varchar({ length: 20 }),
	phone: varchar({ length: 50 }),
	districtId: uuid("district_id"),
	localBodyId: uuid("local_body_id"),
	assemblyId: uuid("assembly_id"),
	wardId: uuid("ward_id"),
	reportBasis: varchar("report_basis", { length: 50 }).default('accrual'),
	drugLicense20Url: text("drug_license_20_url"),
	drugLicense21Url: text("drug_license_21_url"),
	drugLicense20BUrl: text("drug_license_20b_url"),
	drugLicense21BUrl: text("drug_license_21b_url"),
	fssaiUrl: text("fssai_url"),
	msmeUrl: text("msme_url"),
	additionalFields: jsonb("additional_fields"),
}, (table) => [
	index("idx_organization_assembly_id").using("btree", table.assemblyId.asc().nullsLast().op("uuid_ops")),
	index("idx_organization_district_id").using("btree", table.districtId.asc().nullsLast().op("uuid_ops")),
	index("idx_organization_local_body_id").using("btree", table.localBodyId.asc().nullsLast().op("uuid_ops")),
	index("idx_organization_payment_stub_assembly_id").using("btree", table.paymentStubAssemblyId.asc().nullsLast().op("uuid_ops")),
	index("idx_organization_ward_id").using("btree", table.wardId.asc().nullsLast().op("uuid_ops")),
	uniqueIndex("organization_system_id_key").using("btree", table.systemId.asc().nullsLast().op("text_ops")),
	foreignKey({
			columns: [table.assemblyId],
			foreignColumns: [assembliesConstituencies.id],
			name: "organization_assembly_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.districtId],
			foreignColumns: [lsgdDistricts.id],
			name: "organization_district_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.id],
			foreignColumns: [organisationBranchMaster.refId],
			name: "organization_id_to_registry_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.localBodyId],
			foreignColumns: [lsgdLocalBodies.id],
			name: "organization_local_body_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.paymentStubAssemblyId],
			foreignColumns: [assembliesConstituencies.id],
			name: "organization_payment_stub_assembly_id_fkey"
		}),
	foreignKey({
			columns: [table.paymentStubDistrictId],
			foreignColumns: [lsgdDistricts.id],
			name: "organization_payment_stub_district_id_fkey"
		}),
	foreignKey({
			columns: [table.paymentStubLocalBodyId],
			foreignColumns: [lsgdLocalBodies.id],
			name: "organization_payment_stub_local_body_id_fkey"
		}),
	foreignKey({
			columns: [table.paymentStubWardId],
			foreignColumns: [lsgdWards.id],
			name: "organization_payment_stub_ward_id_fkey"
		}),
	foreignKey({
			columns: [table.stateId],
			foreignColumns: [states.id],
			name: "organization_state_id_fkey"
		}),
	foreignKey({
			columns: [table.wardId],
			foreignColumns: [lsgdWards.id],
			name: "organization_ward_id_fkey"
		}).onDelete("set null"),
	unique("organization_slug_key").on(table.slug),
]);

export const branches = pgTable("branches", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	orgId: uuid("org_id").notNull(),
	name: varchar({ length: 255 }).notNull(),
	branchCode: varchar("branch_code", { length: 50 }).notNull(),
	branchType: varchar("branch_type", { length: 10 }),
	email: varchar({ length: 255 }),
	phone: varchar({ length: 50 }),
	website: varchar({ length: 255 }),
	attention: text(),
	street: text(),
	place: text(),
	city: varchar({ length: 100 }),
	state: varchar({ length: 100 }),
	pincode: varchar({ length: 20 }),
	country: varchar({ length: 100 }).default('India').notNull(),
	gstin: varchar({ length: 50 }),
	gstinRegistrationType: varchar("gstin_registration_type", { length: 50 }),
	logoUrl: text("logo_url"),
	subscriptionFrom: date("subscription_from"),
	subscriptionTo: date("subscription_to"),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	isChildLocation: boolean("is_child_location").default(false).notNull(),
	parentBranchId: uuid("parent_branch_id"),
	primaryContactId: uuid("primary_contact_id"),
	gstinLegalName: varchar("gstin_legal_name", { length: 255 }),
	gstinTradeName: varchar("gstin_trade_name", { length: 255 }),
	gstinRegisteredOn: date("gstin_registered_on"),
	gstinReverseCharge: boolean("gstin_reverse_charge").default(false).notNull(),
	gstinImportExport: boolean("gstin_import_export").default(false).notNull(),
	gstinImportExportAccountId: uuid("gstin_import_export_account_id"),
	gstinDigitalServices: boolean("gstin_digital_services").default(false).notNull(),
	defaultTransactionSeriesId: uuid("default_transaction_series_id"),
	districtId: uuid("district_id"),
	localBodyId: uuid("local_body_id"),
	wardId: uuid("ward_id"),
	systemId: varchar("system_id", { length: 20 }).default((nextval(\'branches_system_id_seq').notNull(),
	pan: varchar(),
	industry: varchar(),
	gstTreatment: varchar("gst_treatment"),
	isDrugRegistered: boolean("is_drug_registered").default(false).notNull(),
	drugLicenceType: varchar("drug_licence_type"),
	drugLicence20: varchar("drug_licence_20"),
	drugLicence21: varchar("drug_licence_21"),
	drugLicence20B: varchar("drug_licence_20b"),
	drugLicence21B: varchar("drug_licence_21b"),
	isFssaiRegistered: boolean("is_fssai_registered").default(false).notNull(),
	fssaiNumber: varchar("fssai_number"),
	isMsmeRegistered: boolean("is_msme_registered").default(false).notNull(),
	msmeRegistrationType: varchar("msme_registration_type"),
	msmeNumber: varchar("msme_number"),
	msmeType: varchar("msme_type", { length: 50 }),
	fiscalYear: varchar("fiscal_year"),
	reportBasis: varchar("report_basis").default('accrual'),
	hasSeparatePaymentStubAddress: boolean("has_separate_payment_stub_address").default(false).notNull(),
	paymentStubAddress: text("payment_stub_address"),
	paymentStubAssemblyId: uuid("payment_stub_assembly_id"),
	assemblyId: uuid("assembly_id"),
}, (table) => [
	index("idx_settings_branches_assembly_id").using("btree", table.assemblyId.asc().nullsLast().op("uuid_ops")),
	index("idx_settings_branches_default_transaction_series_id").using("btree", table.defaultTransactionSeriesId.asc().nullsLast().op("uuid_ops")),
	index("idx_settings_branches_district_id").using("btree", table.districtId.asc().nullsLast().op("uuid_ops")),
	index("idx_settings_branches_fiscal_year").using("btree", table.fiscalYear.asc().nullsLast().op("text_ops")),
	index("idx_settings_branches_local_body_id").using("btree", table.localBodyId.asc().nullsLast().op("uuid_ops")),
	index("idx_settings_branches_org_id").using("btree", table.orgId.asc().nullsLast().op("uuid_ops")),
	index("idx_settings_branches_parent_branch_id").using("btree", table.parentBranchId.asc().nullsLast().op("uuid_ops")),
	index("idx_settings_branches_payment_stub_assembly_id").using("btree", table.paymentStubAssemblyId.asc().nullsLast().op("uuid_ops")),
	index("idx_settings_branches_primary_contact_id").using("btree", table.primaryContactId.asc().nullsLast().op("uuid_ops")),
	index("idx_settings_branches_report_basis").using("btree", table.reportBasis.asc().nullsLast().op("text_ops")),
	index("idx_settings_branches_ward_id").using("btree", table.wardId.asc().nullsLast().op("uuid_ops")),
	uniqueIndex("settings_branches_system_id_key").using("btree", table.systemId.asc().nullsLast().op("text_ops")),
	foreignKey({
			columns: [table.id],
			foreignColumns: [organisationBranchMaster.refId],
			name: "branches_id_to_registry_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.assemblyId],
			foreignColumns: [assembliesConstituencies.id],
			name: "settings_branches_assembly_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.branchType],
			foreignColumns: [businessTypes.code],
			name: "settings_branches_branch_type_fkey"
		}),
	foreignKey({
			columns: [table.defaultTransactionSeriesId],
			foreignColumns: [transactionSeries.id],
			name: "settings_branches_default_transaction_series_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.districtId],
			foreignColumns: [lsgdDistricts.id],
			name: "settings_branches_district_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.gstTreatment],
			foreignColumns: [gstTreatments.code],
			name: "settings_branches_gst_treatment_fkey"
		}),
	foreignKey({
			columns: [table.gstinImportExportAccountId],
			foreignColumns: [accounts.id],
			name: "settings_branches_gstin_import_export_account_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.gstinRegistrationType],
			foreignColumns: [gstinRegistrationTypes.code],
			name: "settings_branches_gstin_registration_type_fkey"
		}),
	foreignKey({
			columns: [table.localBodyId],
			foreignColumns: [lsgdLocalBodies.id],
			name: "settings_branches_local_body_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.orgId],
			foreignColumns: [organization.id],
			name: "settings_branches_org_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.parentBranchId],
			foreignColumns: [table.id],
			name: "settings_branches_parent_branch_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.paymentStubAssemblyId],
			foreignColumns: [assembliesConstituencies.id],
			name: "settings_branches_payment_stub_assembly_id_fkey"
		}),
	foreignKey({
			columns: [table.wardId],
			foreignColumns: [lsgdWards.id],
			name: "settings_branches_ward_id_fkey"
		}).onDelete("set null"),
	unique("settings_branches_org_code_unique").on(table.orgId, table.branchCode),
]);

export const branchUserAccess = pgTable("branch_user_access", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	userId: uuid("user_id").notNull(),
	roleId: uuid("role_id"),
	isDefaultBranch: boolean("is_default_branch").default(false),
	permissions: jsonb().default({}),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	index("idx_settings_branch_user_access_role_id").using("btree", table.roleId.asc().nullsLast().op("uuid_ops")),
	index("idx_settings_branch_user_access_user_id").using("btree", table.userId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "branch_user_access_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.roleId],
			foreignColumns: [roles.id],
			name: "settings_branch_user_access_role_id_fkey"
		}),
	foreignKey({
			columns: [table.userId],
			foreignColumns: [users.id],
			name: "settings_branch_user_access_user_id_fkey"
		}).onDelete("cascade"),
]);

export const reportingTags = pgTable("reporting_tags", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	tagName: varchar("tag_name", { length: 100 }).notNull(),
	isActive: boolean("is_active").default(true),
	entityId: uuid("entity_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "reporting_tags_entity_id_fkey"
		}),
]);

export const compositeItemBranchInventorySettings = pgTable("composite_item_branch_inventory_settings", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	entityId: uuid("entity_id").notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	compositeItemId: uuid("composite_item_id").notNull(),
	reorderPoint: integer("reorder_point").default(0).notNull(),
	reorderTermId: uuid("reorder_term_id"),
	isActive: boolean("is_active").default(true).notNull(),
	createdById: uuid("created_by_id"),
	updatedById: uuid("updated_by_id"),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_cibis_composite_item_id").using("btree", table.compositeItemId.asc().nullsLast().op("uuid_ops")),
	index("idx_cibis_entity_id").using("btree", table.entityId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.compositeItemId],
			foreignColumns: [compositeItems.id],
			name: "cibis_composite_item_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "cibis_entity_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.reorderTermId],
			foreignColumns: [reorderTerms.id],
			name: "cibis_reorder_term_id_fkey"
		}).onDelete("set null"),
	unique("uq_cibis_item_entity").on(table.entityId, table.compositeItemId),
]);

export const productBranchInventorySettings = pgTable("product_branch_inventory_settings", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	entityId: uuid("entity_id").notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	productId: uuid("product_id").notNull(),
	reorderPoint: integer("reorder_point").default(0).notNull(),
	reorderTermId: uuid("reorder_term_id"),
	isActive: boolean("is_active").default(true).notNull(),
	createdById: uuid("created_by_id"),
	updatedById: uuid("updated_by_id"),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	index("idx_pbis_entity_id").using("btree", table.entityId.asc().nullsLast().op("uuid_ops")),
	index("idx_pbis_product_id").using("btree", table.productId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "product_branch_inventory_settings_entity_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "product_branch_inventory_settings_product_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.reorderTermId],
			foreignColumns: [reorderTerms.id],
			name: "product_branch_inventory_settings_reorder_term_id_fkey"
		}).onDelete("set null"),
	unique("uq_pbis_product_entity").on(table.entityId, table.productId),
]);

export const branchInventory = pgTable("branch_inventory", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	entityId: uuid("entity_id").notNull(),
	productId: uuid("product_id").notNull(),
	currentStock: integer("current_stock").default(0).notNull(),
	reservedStock: integer("reserved_stock").default(0).notNull(),
	availableStock: integer("available_stock").generatedAlwaysAs(sql`(current_stock - reserved_stock)`),
	batchNo: varchar("batch_no", { length: 100 }),
	expiryDate: date("expiry_date"),
	minStockLevel: integer("min_stock_level").default(0),
	maxStockLevel: integer("max_stock_level").default(0),
	lastStockUpdate: timestamp("last_stock_update", { withTimezone: true, mode: 'string' }).defaultNow(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
}, (table) => [
	index("idx_branch_inventory_entity").using("btree", table.entityId.asc().nullsLast().op("uuid_ops")),
	index("idx_branch_inventory_entity_product").using("btree", table.entityId.asc().nullsLast().op("uuid_ops"), table.productId.asc().nullsLast().op("uuid_ops")),
	index("idx_branch_inventory_expiry").using("btree", table.expiryDate.asc().nullsLast().op("date_ops")),
	index("idx_branch_inventory_product").using("btree", table.productId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "branch_inventory_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.productId],
			foreignColumns: [products.id],
			name: "branch_inventory_product_id_fkey"
		}),
	unique("branch_inventory_entity_id_product_id_batch_no_key").on(table.entityId, table.productId, table.batchNo),
	check("branch_inventory_current_stock_check", sql`current_stock >= 0`),
]);

export const warehouses = pgTable("warehouses", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: varchar({ length: 255 }).notNull(),
	attention: text(),
	street: text(),
	place: text(),
	city: text(),
	state: text(),
	phone: varchar({ length: 50 }),
	email: varchar({ length: 255 }),
	isActive: boolean("is_active").default(true).notNull(),
	createdAt: timestamp("created_at", { mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { mode: 'string' }).defaultNow().notNull(),
	warehouseCode: varchar("warehouse_code", { length: 50 }),
	pincode: varchar({ length: 20 }),
	country: varchar({ length: 100 }).default('India').notNull(),
	customerId: uuid("customer_id"),
	vendorId: uuid("vendor_id"),
	districtId: uuid("district_id"),
	localBodyId: uuid("local_body_id"),
	wardId: uuid("ward_id"),
	assemblyId: uuid("assembly_id"),
	entityId: uuid("entity_id").notNull(),
	orgId: uuid("org_id").default(sql`'00000000-0000-0000-0000-000000000000'`).notNull(),
	sourceBranchId: uuid("source_branch_id"),
	isDefaultForBranch: boolean("is_default_for_branch").default(false).notNull(),
}, (table) => [
	index("idx_warehouses_assembly_id").using("btree", table.assemblyId.asc().nullsLast().op("uuid_ops")),
	index("idx_warehouses_customer_id").using("btree", table.customerId.asc().nullsLast().op("uuid_ops")),
	index("idx_warehouses_district_id").using("btree", table.districtId.asc().nullsLast().op("uuid_ops")),
	index("idx_warehouses_local_body_id").using("btree", table.localBodyId.asc().nullsLast().op("uuid_ops")),
	uniqueIndex("idx_warehouses_one_default_per_branch").using("btree", table.sourceBranchId.asc().nullsLast().op("uuid_ops")).where(sql`(is_default_for_branch = true)`),
	index("idx_warehouses_source_branch_id").using("btree", table.sourceBranchId.asc().nullsLast().op("uuid_ops")),
	index("idx_warehouses_vendor_id").using("btree", table.vendorId.asc().nullsLast().op("uuid_ops")),
	index("idx_warehouses_ward_id").using("btree", table.wardId.asc().nullsLast().op("uuid_ops")),
	foreignKey({
			columns: [table.assemblyId],
			foreignColumns: [assembliesConstituencies.id],
			name: "warehouses_assembly_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.customerId],
			foreignColumns: [customers.id],
			name: "warehouses_customer_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.districtId],
			foreignColumns: [lsgdDistricts.id],
			name: "warehouses_district_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.entityId],
			foreignColumns: [organisationBranchMaster.id],
			name: "warehouses_entity_id_fkey"
		}),
	foreignKey({
			columns: [table.localBodyId],
			foreignColumns: [lsgdLocalBodies.id],
			name: "warehouses_local_body_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.sourceBranchId],
			foreignColumns: [branches.id],
			name: "warehouses_source_branch_id_fkey"
		}),
	foreignKey({
			columns: [table.vendorId],
			foreignColumns: [vendors.id],
			name: "warehouses_vendor_id_fkey"
		}).onDelete("set null"),
	foreignKey({
			columns: [table.wardId],
			foreignColumns: [lsgdWards.id],
			name: "warehouses_ward_id_fkey"
		}).onDelete("set null"),
]);

export const manualJournalTagMappings = pgTable("manual_journal_tag_mappings", {
	manualJournalItemId: uuid("manual_journal_item_id").notNull(),
	reportingTagId: uuid("reporting_tag_id").notNull(),
}, (table) => [
	foreignKey({
			columns: [table.manualJournalItemId],
			foreignColumns: [manualJournalItems.id],
			name: "accounts_manual_journal_tag_mapping_manual_journal_item_id_fkey"
		}).onDelete("cascade"),
	foreignKey({
			columns: [table.reportingTagId],
			foreignColumns: [reportingTags.id],
			name: "accounts_manual_journal_tag_mappings_reporting_tag_id_fkey"
		}).onDelete("cascade"),
	primaryKey({ columns: [table.manualJournalItemId, table.reportingTagId], name: "accounts_manual_journal_tag_mappings_pkey"}),
]);
export const auditLogsAll = pgView("audit_logs_all", {	id: uuid(),
	tableName: varchar("table_name", { length: 100 }),
	recordId: uuid("record_id"),
	action: varchar({ length: 10 }),
	oldValues: jsonb("old_values"),
	newValues: jsonb("new_values"),
	userId: uuid("user_id"),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }),
	orgId: uuid("org_id"),
	actorName: text("actor_name"),
	schemaName: text("schema_name"),
	recordPk: text("record_pk"),
	changedColumns: text("changed_columns"),
	// You can use { mode: "bigint" } if numbers are exceeding js number limitations
	txid: bigint({ mode: "number" }),
	source: text(),
	moduleName: text("module_name"),
	requestId: text("request_id"),
	entityId: uuid("entity_id"),
	archivedAt: timestamp("archived_at", { withTimezone: true, mode: 'string' }),
}).as(sql`SELECT audit_logs.id, audit_logs.table_name, audit_logs.record_id, audit_logs.action, audit_logs.old_values, audit_logs.new_values, audit_logs.user_id, audit_logs.created_at, audit_logs.org_id, audit_logs.actor_name, audit_logs.schema_name, audit_logs.record_pk, audit_logs.changed_columns, audit_logs.txid, audit_logs.source, audit_logs.module_name, audit_logs.request_id, audit_logs.entity_id, NULL::timestamp with time zone AS archived_at FROM audit_logs UNION ALL SELECT audit_logs_archive.id, audit_logs_archive.table_name, audit_logs_archive.record_id, audit_logs_archive.action, audit_logs_archive.old_values, audit_logs_archive.new_values, audit_logs_archive.user_id, audit_logs_archive.created_at, audit_logs_archive.org_id, audit_logs_archive.actor_name, audit_logs_archive.schema_name, audit_logs_archive.record_pk, audit_logs_archive.changed_columns, audit_logs_archive.txid, audit_logs_archive.source, audit_logs_archive.module_name, audit_logs_archive.request_id, audit_logs_archive.entity_id, audit_logs_archive.archived_at FROM audit_logs_archive`);

export const auditLogsWithBranchSystemId = pgView("audit_logs_with_branch_system_id", {	id: uuid(),
	tableName: varchar("table_name", { length: 100 }),
	recordId: uuid("record_id"),
	action: varchar({ length: 10 }),
	oldValues: jsonb("old_values"),
	newValues: jsonb("new_values"),
	userId: uuid("user_id"),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }),
	orgId: uuid("org_id"),
	actorName: text("actor_name"),
	schemaName: text("schema_name"),
	recordPk: text("record_pk"),
	changedColumns: text("changed_columns"),
	// You can use { mode: "bigint" } if numbers are exceeding js number limitations
	txid: bigint({ mode: "number" }),
	source: text(),
	moduleName: text("module_name"),
	requestId: text("request_id"),
	entityId: uuid("entity_id"),
	systemId: varchar("system_id", { length: 20 }),
}).as(sql`SELECT al.id, al.table_name, al.record_id, al.action, al.old_values, al.new_values, al.user_id, al.created_at, al.org_id, al.actor_name, al.schema_name, al.record_pk, al.changed_columns, al.txid, al.source, al.module_name, al.request_id, al.entity_id, b.system_id FROM audit_logs al JOIN organisation_branch_master obm ON al.entity_id = obm.id LEFT JOIN branches b ON obm.ref_id = b.id`);