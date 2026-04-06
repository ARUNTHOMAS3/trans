import { relations } from "drizzle-orm/relations";
import { products, batchMaster, taxGroups, taxGroupTaxes, associateTaxes, countries, states, customers, salesPaymentLinks, accounts, purchasesPurchaseOrderItems, purchasesPurchaseOrders, brands, buyingRules, categories, manufacturers, vendors, racks, schedules, storageLocations, units, purchasesPurchaseOrderAttachments, salesOrders, paymentTerms, priceLists, tdsRates, warehouses, salesOrderItems, accountsFiscalYears, accountsManualJournals, accountsRecurringJournals, salesOrderAttachments, accountTransactions, accountsManualJournalAttachments, contents, productContents, strengths, settingsBranches, settingsBranchTransactionSeries, organization, settingsTransactionSeries, settingsBranchUsers, settingsLocalBodies, settingsWards, shipmentPreferences, vendorContactPersons, salesPayments, settingsDistricts, compositeItemParts, compositeItems, vendorBankAccounts, tdsSections, uqc, accountsRecurringJournalItems, timezones, tdsGroups, tdsGroupItems, accountsJournalTemplateItems, accountsJournalTemplates, accountsManualJournalItems, productOutletInventorySettings, reorderTerms, compositeItemOutletInventorySettings, priceListItems, itemVendorMappings, priceListVolumeRanges, customerContactPersons, currencies, settingsBranding, settingsUserLocationAccess, users, settingsRoles, settingsBranchUserAccess, accountsManualJournalTagMappings, accountsReportingTags } from "./schema";

export const batchMasterRelations = relations(batchMaster, ({one, many}) => ({
	product: one(products, {
		fields: [batchMaster.productId],
		references: [products.id]
	}),
	salesOrderItems: many(salesOrderItems),
}));

export const productsRelations = relations(products, ({one, many}) => ({
	batchMasters: many(batchMaster),
	purchasesPurchaseOrderItems: many(purchasesPurchaseOrderItems),
	brand: one(brands, {
		fields: [products.brandId],
		references: [brands.id]
	}),
	buyingRule: one(buyingRules, {
		fields: [products.buyingRuleId],
		references: [buyingRules.id]
	}),
	category: one(categories, {
		fields: [products.categoryId],
		references: [categories.id]
	}),
	associateTax: one(associateTaxes, {
		fields: [products.interStateTaxId],
		references: [associateTaxes.id]
	}),
	taxGroup: one(taxGroups, {
		fields: [products.intraStateTaxId],
		references: [taxGroups.id]
	}),
	account_inventoryAccountId: one(accounts, {
		fields: [products.inventoryAccountId],
		references: [accounts.id],
		relationName: "products_inventoryAccountId_accounts_id"
	}),
	manufacturer: one(manufacturers, {
		fields: [products.manufacturerId],
		references: [manufacturers.id]
	}),
	vendor: one(vendors, {
		fields: [products.preferredVendorId],
		references: [vendors.id]
	}),
	account_purchaseAccountId: one(accounts, {
		fields: [products.purchaseAccountId],
		references: [accounts.id],
		relationName: "products_purchaseAccountId_accounts_id"
	}),
	rack: one(racks, {
		fields: [products.rackId],
		references: [racks.id]
	}),
	account_salesAccountId: one(accounts, {
		fields: [products.salesAccountId],
		references: [accounts.id],
		relationName: "products_salesAccountId_accounts_id"
	}),
	schedule: one(schedules, {
		fields: [products.scheduleOfDrugId],
		references: [schedules.id]
	}),
	storageLocation: one(storageLocations, {
		fields: [products.storageId],
		references: [storageLocations.id]
	}),
	unit: one(units, {
		fields: [products.unitId],
		references: [units.id]
	}),
	salesOrderItems: many(salesOrderItems),
	productContents: many(productContents),
	compositeItemParts: many(compositeItemParts),
	productOutletInventorySettings: many(productOutletInventorySettings),
	priceListItems: many(priceListItems),
	itemVendorMappings: many(itemVendorMappings),
}));

export const taxGroupTaxesRelations = relations(taxGroupTaxes, ({one}) => ({
	taxGroup: one(taxGroups, {
		fields: [taxGroupTaxes.taxGroupId],
		references: [taxGroups.id]
	}),
	associateTax: one(associateTaxes, {
		fields: [taxGroupTaxes.taxId],
		references: [associateTaxes.id]
	}),
}));

export const taxGroupsRelations = relations(taxGroups, ({many}) => ({
	taxGroupTaxes: many(taxGroupTaxes),
	products: many(products),
}));

export const associateTaxesRelations = relations(associateTaxes, ({many}) => ({
	taxGroupTaxes: many(taxGroupTaxes),
	purchasesPurchaseOrderItems: many(purchasesPurchaseOrderItems),
	products: many(products),
	salesOrderItems: many(salesOrderItems),
	compositeItems_interStateTaxId: many(compositeItems, {
		relationName: "compositeItems_interStateTaxId_associateTaxes_id"
	}),
	compositeItems_intraStateTaxId: many(compositeItems, {
		relationName: "compositeItems_intraStateTaxId_associateTaxes_id"
	}),
}));

export const statesRelations = relations(states, ({one, many}) => ({
	country: one(countries, {
		fields: [states.stateId],
		references: [countries.id]
	}),
	settingsDistricts: many(settingsDistricts),
	customers_billingAddressStateId: many(customers, {
		relationName: "customers_billingAddressStateId_states_id"
	}),
	customers_shippingAddressStateId: many(customers, {
		relationName: "customers_shippingAddressStateId_states_id"
	}),
	organizations: many(organization),
}));

export const countriesRelations = relations(countries, ({one, many}) => ({
	states: many(states),
	timezone: one(timezones, {
		fields: [countries.primaryTimezoneId],
		references: [timezones.id],
		relationName: "countries_primaryTimezoneId_timezones_id"
	}),
	customers_billingAddressCountryId: many(customers, {
		relationName: "customers_billingAddressCountryId_countries_id"
	}),
	customers_shippingAddressCountryId: many(customers, {
		relationName: "customers_shippingAddressCountryId_countries_id"
	}),
	timezones: many(timezones, {
		relationName: "timezones_countryId_countries_id"
	}),
}));

export const salesPaymentLinksRelations = relations(salesPaymentLinks, ({one}) => ({
	customer: one(customers, {
		fields: [salesPaymentLinks.customerId],
		references: [customers.id]
	}),
}));

export const customersRelations = relations(customers, ({one, many}) => ({
	salesPaymentLinks: many(salesPaymentLinks),
	salesOrders: many(salesOrders),
	warehouses: many(warehouses),
	purchasesPurchaseOrders: many(purchasesPurchaseOrders),
	salesPayments: many(salesPayments),
	customerContactPersons: many(customerContactPersons),
	country_billingAddressCountryId: one(countries, {
		fields: [customers.billingAddressCountryId],
		references: [countries.id],
		relationName: "customers_billingAddressCountryId_countries_id"
	}),
	state_billingAddressStateId: one(states, {
		fields: [customers.billingAddressStateId],
		references: [states.id],
		relationName: "customers_billingAddressStateId_states_id"
	}),
	currency: one(currencies, {
		fields: [customers.currencyId],
		references: [currencies.id]
	}),
	customer: one(customers, {
		fields: [customers.parentCustomerId],
		references: [customers.id],
		relationName: "customers_parentCustomerId_customers_id"
	}),
	customers: many(customers, {
		relationName: "customers_parentCustomerId_customers_id"
	}),
	priceList: one(priceLists, {
		fields: [customers.priceListId],
		references: [priceLists.id]
	}),
	country_shippingAddressCountryId: one(countries, {
		fields: [customers.shippingAddressCountryId],
		references: [countries.id],
		relationName: "customers_shippingAddressCountryId_countries_id"
	}),
	state_shippingAddressStateId: one(states, {
		fields: [customers.shippingAddressStateId],
		references: [states.id],
		relationName: "customers_shippingAddressStateId_states_id"
	}),
}));

export const purchasesPurchaseOrderItemsRelations = relations(purchasesPurchaseOrderItems, ({one}) => ({
	account: one(accounts, {
		fields: [purchasesPurchaseOrderItems.accountId],
		references: [accounts.id]
	}),
	product: one(products, {
		fields: [purchasesPurchaseOrderItems.productId],
		references: [products.id]
	}),
	purchasesPurchaseOrder: one(purchasesPurchaseOrders, {
		fields: [purchasesPurchaseOrderItems.purchaseOrderId],
		references: [purchasesPurchaseOrders.id]
	}),
	associateTax: one(associateTaxes, {
		fields: [purchasesPurchaseOrderItems.taxId],
		references: [associateTaxes.id]
	}),
}));

export const accountsRelations = relations(accounts, ({one, many}) => ({
	purchasesPurchaseOrderItems: many(purchasesPurchaseOrderItems),
	products_inventoryAccountId: many(products, {
		relationName: "products_inventoryAccountId_accounts_id"
	}),
	products_purchaseAccountId: many(products, {
		relationName: "products_purchaseAccountId_accounts_id"
	}),
	products_salesAccountId: many(products, {
		relationName: "products_salesAccountId_accounts_id"
	}),
	account: one(accounts, {
		fields: [accounts.parentId],
		references: [accounts.id],
		relationName: "accounts_parentId_accounts_id"
	}),
	accounts: many(accounts, {
		relationName: "accounts_parentId_accounts_id"
	}),
	accountTransactions: many(accountTransactions),
	tdsRates_payableAccountId: many(tdsRates, {
		relationName: "tdsRates_payableAccountId_accounts_id"
	}),
	tdsRates_receivableAccountId: many(tdsRates, {
		relationName: "tdsRates_receivableAccountId_accounts_id"
	}),
	accountsRecurringJournalItems: many(accountsRecurringJournalItems),
	accountsJournalTemplateItems: many(accountsJournalTemplateItems),
	accountsManualJournalItems: many(accountsManualJournalItems),
	compositeItems_inventoryAccountId: many(compositeItems, {
		relationName: "compositeItems_inventoryAccountId_accounts_id"
	}),
	compositeItems_purchaseAccountId: many(compositeItems, {
		relationName: "compositeItems_purchaseAccountId_accounts_id"
	}),
	compositeItems_salesAccountId: many(compositeItems, {
		relationName: "compositeItems_salesAccountId_accounts_id"
	}),
	settingsBranches: many(settingsBranches),
}));

export const purchasesPurchaseOrdersRelations = relations(purchasesPurchaseOrders, ({one, many}) => ({
	purchasesPurchaseOrderItems: many(purchasesPurchaseOrderItems),
	purchasesPurchaseOrderAttachments: many(purchasesPurchaseOrderAttachments),
	customer: one(customers, {
		fields: [purchasesPurchaseOrders.deliveryCustomerId],
		references: [customers.id]
	}),
	warehouse_deliveryWarehouseId: one(warehouses, {
		fields: [purchasesPurchaseOrders.deliveryWarehouseId],
		references: [warehouses.id],
		relationName: "purchasesPurchaseOrders_deliveryWarehouseId_warehouses_id"
	}),
	paymentTerm: one(paymentTerms, {
		fields: [purchasesPurchaseOrders.paymentTermsId],
		references: [paymentTerms.id]
	}),
	shipmentPreference: one(shipmentPreferences, {
		fields: [purchasesPurchaseOrders.shipmentPreferenceId],
		references: [shipmentPreferences.id]
	}),
	tdsRate: one(tdsRates, {
		fields: [purchasesPurchaseOrders.tdsId],
		references: [tdsRates.id]
	}),
	vendor: one(vendors, {
		fields: [purchasesPurchaseOrders.vendorId],
		references: [vendors.id]
	}),
	warehouse_warehouseId: one(warehouses, {
		fields: [purchasesPurchaseOrders.warehouseId],
		references: [warehouses.id],
		relationName: "purchasesPurchaseOrders_warehouseId_warehouses_id"
	}),
}));

export const brandsRelations = relations(brands, ({many}) => ({
	products: many(products),
	compositeItems: many(compositeItems),
}));

export const buyingRulesRelations = relations(buyingRules, ({many}) => ({
	products: many(products),
}));

export const categoriesRelations = relations(categories, ({one, many}) => ({
	products: many(products),
	category: one(categories, {
		fields: [categories.parentId],
		references: [categories.id],
		relationName: "categories_parentId_categories_id"
	}),
	categories: many(categories, {
		relationName: "categories_parentId_categories_id"
	}),
	compositeItems: many(compositeItems),
}));

export const manufacturersRelations = relations(manufacturers, ({many}) => ({
	products: many(products),
	compositeItems: many(compositeItems),
}));

export const vendorsRelations = relations(vendors, ({many}) => ({
	products: many(products),
	warehouses: many(warehouses),
	purchasesPurchaseOrders: many(purchasesPurchaseOrders),
	vendorContactPersons: many(vendorContactPersons),
	vendorBankAccounts: many(vendorBankAccounts),
}));

export const racksRelations = relations(racks, ({many}) => ({
	products: many(products),
}));

export const schedulesRelations = relations(schedules, ({many}) => ({
	products: many(products),
	productContents: many(productContents),
}));

export const storageLocationsRelations = relations(storageLocations, ({many}) => ({
	products: many(products),
}));

export const unitsRelations = relations(units, ({one, many}) => ({
	products: many(products),
	uqc: one(uqc, {
		fields: [units.uqcId],
		references: [uqc.id]
	}),
	compositeItems: many(compositeItems),
}));

export const purchasesPurchaseOrderAttachmentsRelations = relations(purchasesPurchaseOrderAttachments, ({one}) => ({
	purchasesPurchaseOrder: one(purchasesPurchaseOrders, {
		fields: [purchasesPurchaseOrderAttachments.purchaseOrderId],
		references: [purchasesPurchaseOrders.id]
	}),
}));

export const salesOrdersRelations = relations(salesOrders, ({one, many}) => ({
	customer: one(customers, {
		fields: [salesOrders.customerId],
		references: [customers.id]
	}),
	paymentTerm: one(paymentTerms, {
		fields: [salesOrders.paymentTermId],
		references: [paymentTerms.id]
	}),
	priceList: one(priceLists, {
		fields: [salesOrders.priceListId],
		references: [priceLists.id]
	}),
	tdsRate: one(tdsRates, {
		fields: [salesOrders.tdsTcsTaxId],
		references: [tdsRates.id]
	}),
	warehouse: one(warehouses, {
		fields: [salesOrders.warehouseId],
		references: [warehouses.id]
	}),
	salesOrderItems: many(salesOrderItems),
	salesOrderAttachments: many(salesOrderAttachments),
}));

export const paymentTermsRelations = relations(paymentTerms, ({many}) => ({
	salesOrders: many(salesOrders),
	purchasesPurchaseOrders: many(purchasesPurchaseOrders),
}));

export const priceListsRelations = relations(priceLists, ({many}) => ({
	salesOrders: many(salesOrders),
	priceListItems: many(priceListItems),
	customers: many(customers),
}));

export const tdsRatesRelations = relations(tdsRates, ({one, many}) => ({
	salesOrders: many(salesOrders),
	purchasesPurchaseOrders: many(purchasesPurchaseOrders),
	account_payableAccountId: one(accounts, {
		fields: [tdsRates.payableAccountId],
		references: [accounts.id],
		relationName: "tdsRates_payableAccountId_accounts_id"
	}),
	account_receivableAccountId: one(accounts, {
		fields: [tdsRates.receivableAccountId],
		references: [accounts.id],
		relationName: "tdsRates_receivableAccountId_accounts_id"
	}),
	tdsSection: one(tdsSections, {
		fields: [tdsRates.sectionId],
		references: [tdsSections.id]
	}),
	tdsGroupItems: many(tdsGroupItems),
}));

export const warehousesRelations = relations(warehouses, ({one, many}) => ({
	salesOrders: many(salesOrders),
	settingsBranch: one(settingsBranches, {
		fields: [warehouses.branchId],
		references: [settingsBranches.id]
	}),
	customer: one(customers, {
		fields: [warehouses.customerId],
		references: [customers.id]
	}),
	organization: one(organization, {
		fields: [warehouses.orgId],
		references: [organization.id]
	}),
	vendor: one(vendors, {
		fields: [warehouses.vendorId],
		references: [vendors.id]
	}),
	purchasesPurchaseOrders_deliveryWarehouseId: many(purchasesPurchaseOrders, {
		relationName: "purchasesPurchaseOrders_deliveryWarehouseId_warehouses_id"
	}),
	purchasesPurchaseOrders_warehouseId: many(purchasesPurchaseOrders, {
		relationName: "purchasesPurchaseOrders_warehouseId_warehouses_id"
	}),
}));

export const salesOrderItemsRelations = relations(salesOrderItems, ({one}) => ({
	batchMaster: one(batchMaster, {
		fields: [salesOrderItems.batchId],
		references: [batchMaster.id]
	}),
	product: one(products, {
		fields: [salesOrderItems.productId],
		references: [products.id]
	}),
	salesOrder: one(salesOrders, {
		fields: [salesOrderItems.salesOrderId],
		references: [salesOrders.id]
	}),
	associateTax: one(associateTaxes, {
		fields: [salesOrderItems.taxId],
		references: [associateTaxes.id]
	}),
}));

export const accountsManualJournalsRelations = relations(accountsManualJournals, ({one, many}) => ({
	accountsFiscalYear: one(accountsFiscalYears, {
		fields: [accountsManualJournals.fiscalYearId],
		references: [accountsFiscalYears.id]
	}),
	accountsRecurringJournal: one(accountsRecurringJournals, {
		fields: [accountsManualJournals.recurringJournalId],
		references: [accountsRecurringJournals.id]
	}),
	accountsManualJournalAttachments: many(accountsManualJournalAttachments),
	accountsManualJournalItems: many(accountsManualJournalItems),
}));

export const accountsFiscalYearsRelations = relations(accountsFiscalYears, ({many}) => ({
	accountsManualJournals: many(accountsManualJournals),
}));

export const accountsRecurringJournalsRelations = relations(accountsRecurringJournals, ({many}) => ({
	accountsManualJournals: many(accountsManualJournals),
	accountsRecurringJournalItems: many(accountsRecurringJournalItems),
}));

export const salesOrderAttachmentsRelations = relations(salesOrderAttachments, ({one}) => ({
	salesOrder: one(salesOrders, {
		fields: [salesOrderAttachments.salesOrderId],
		references: [salesOrders.id]
	}),
}));

export const accountTransactionsRelations = relations(accountTransactions, ({one}) => ({
	account: one(accounts, {
		fields: [accountTransactions.accountId],
		references: [accounts.id]
	}),
}));

export const accountsManualJournalAttachmentsRelations = relations(accountsManualJournalAttachments, ({one}) => ({
	accountsManualJournal: one(accountsManualJournals, {
		fields: [accountsManualJournalAttachments.manualJournalId],
		references: [accountsManualJournals.id]
	}),
}));

export const productContentsRelations = relations(productContents, ({one}) => ({
	content: one(contents, {
		fields: [productContents.contentId],
		references: [contents.id]
	}),
	product: one(products, {
		fields: [productContents.productId],
		references: [products.id]
	}),
	schedule: one(schedules, {
		fields: [productContents.sheduleId],
		references: [schedules.id]
	}),
	strength: one(strengths, {
		fields: [productContents.strengthId],
		references: [strengths.id]
	}),
}));

export const contentsRelations = relations(contents, ({many}) => ({
	productContents: many(productContents),
}));

export const strengthsRelations = relations(strengths, ({many}) => ({
	productContents: many(productContents),
}));

export const settingsBranchTransactionSeriesRelations = relations(settingsBranchTransactionSeries, ({one}) => ({
	settingsBranch: one(settingsBranches, {
		fields: [settingsBranchTransactionSeries.branchId],
		references: [settingsBranches.id]
	}),
	organization: one(organization, {
		fields: [settingsBranchTransactionSeries.orgId],
		references: [organization.id]
	}),
	settingsTransactionSery: one(settingsTransactionSeries, {
		fields: [settingsBranchTransactionSeries.transactionSeriesId],
		references: [settingsTransactionSeries.id]
	}),
}));

export const settingsBranchesRelations = relations(settingsBranches, ({one, many}) => ({
	settingsBranchTransactionSeries: many(settingsBranchTransactionSeries),
	settingsBranchUsers: many(settingsBranchUsers),
	warehouses: many(warehouses),
	settingsTransactionSery: one(settingsTransactionSeries, {
		fields: [settingsBranches.defaultTransactionSeriesId],
		references: [settingsTransactionSeries.id]
	}),
	settingsDistrict: one(settingsDistricts, {
		fields: [settingsBranches.districtId],
		references: [settingsDistricts.id]
	}),
	account: one(accounts, {
		fields: [settingsBranches.gstinImportExportAccountId],
		references: [accounts.id]
	}),
	settingsLocalBody: one(settingsLocalBodies, {
		fields: [settingsBranches.localBodyId],
		references: [settingsLocalBodies.id]
	}),
	organization: one(organization, {
		fields: [settingsBranches.orgId],
		references: [organization.id]
	}),
	settingsBranch: one(settingsBranches, {
		fields: [settingsBranches.parentBranchId],
		references: [settingsBranches.id],
		relationName: "settingsBranches_parentBranchId_settingsBranches_id"
	}),
	settingsBranches: many(settingsBranches, {
		relationName: "settingsBranches_parentBranchId_settingsBranches_id"
	}),
	settingsWard: one(settingsWards, {
		fields: [settingsBranches.wardId],
		references: [settingsWards.id]
	}),
	settingsBranchUserAccesses: many(settingsBranchUserAccess),
}));

export const organizationRelations = relations(organization, ({one, many}) => ({
	settingsBranchTransactionSeries: many(settingsBranchTransactionSeries),
	settingsBranchUsers: many(settingsBranchUsers),
	warehouses: many(warehouses),
	settingsBrandings: many(settingsBranding),
	settingsUserLocationAccesses: many(settingsUserLocationAccess),
	users: many(users),
	settingsRoles: many(settingsRoles),
	settingsBranches: many(settingsBranches),
	settingsDistrict: one(settingsDistricts, {
		fields: [organization.paymentStubDistrictId],
		references: [settingsDistricts.id]
	}),
	settingsLocalBody: one(settingsLocalBodies, {
		fields: [organization.paymentStubLocalBodyId],
		references: [settingsLocalBodies.id]
	}),
	settingsWard: one(settingsWards, {
		fields: [organization.paymentStubWardId],
		references: [settingsWards.id]
	}),
	state: one(states, {
		fields: [organization.stateId],
		references: [states.id]
	}),
	settingsBranchUserAccesses: many(settingsBranchUserAccess),
}));

export const settingsTransactionSeriesRelations = relations(settingsTransactionSeries, ({many}) => ({
	settingsBranchTransactionSeries: many(settingsBranchTransactionSeries),
	settingsBranches: many(settingsBranches),
}));

export const settingsBranchUsersRelations = relations(settingsBranchUsers, ({one}) => ({
	settingsBranch: one(settingsBranches, {
		fields: [settingsBranchUsers.branchId],
		references: [settingsBranches.id]
	}),
	organization: one(organization, {
		fields: [settingsBranchUsers.orgId],
		references: [organization.id]
	}),
}));

export const settingsWardsRelations = relations(settingsWards, ({one, many}) => ({
	settingsLocalBody: one(settingsLocalBodies, {
		fields: [settingsWards.localBodyId],
		references: [settingsLocalBodies.id]
	}),
	settingsBranches: many(settingsBranches),
	organizations: many(organization),
}));

export const settingsLocalBodiesRelations = relations(settingsLocalBodies, ({one, many}) => ({
	settingsWards: many(settingsWards),
	settingsDistrict: one(settingsDistricts, {
		fields: [settingsLocalBodies.districtId],
		references: [settingsDistricts.id]
	}),
	settingsBranches: many(settingsBranches),
	organizations: many(organization),
}));

export const shipmentPreferencesRelations = relations(shipmentPreferences, ({many}) => ({
	purchasesPurchaseOrders: many(purchasesPurchaseOrders),
}));

export const vendorContactPersonsRelations = relations(vendorContactPersons, ({one}) => ({
	vendor: one(vendors, {
		fields: [vendorContactPersons.vendorId],
		references: [vendors.id]
	}),
}));

export const salesPaymentsRelations = relations(salesPayments, ({one}) => ({
	customer: one(customers, {
		fields: [salesPayments.customerId],
		references: [customers.id]
	}),
}));

export const settingsDistrictsRelations = relations(settingsDistricts, ({one, many}) => ({
	state: one(states, {
		fields: [settingsDistricts.stateId],
		references: [states.id]
	}),
	settingsLocalBodies: many(settingsLocalBodies),
	settingsBranches: many(settingsBranches),
	organizations: many(organization),
}));

export const compositeItemPartsRelations = relations(compositeItemParts, ({one}) => ({
	product: one(products, {
		fields: [compositeItemParts.componentProductId],
		references: [products.id]
	}),
	compositeItem: one(compositeItems, {
		fields: [compositeItemParts.compositeItemId],
		references: [compositeItems.id]
	}),
}));

export const compositeItemsRelations = relations(compositeItems, ({one, many}) => ({
	compositeItemParts: many(compositeItemParts),
	compositeItemOutletInventorySettings: many(compositeItemOutletInventorySettings),
	brand: one(brands, {
		fields: [compositeItems.brandId],
		references: [brands.id]
	}),
	category: one(categories, {
		fields: [compositeItems.categoryId],
		references: [categories.id]
	}),
	associateTax_interStateTaxId: one(associateTaxes, {
		fields: [compositeItems.interStateTaxId],
		references: [associateTaxes.id],
		relationName: "compositeItems_interStateTaxId_associateTaxes_id"
	}),
	associateTax_intraStateTaxId: one(associateTaxes, {
		fields: [compositeItems.intraStateTaxId],
		references: [associateTaxes.id],
		relationName: "compositeItems_intraStateTaxId_associateTaxes_id"
	}),
	account_inventoryAccountId: one(accounts, {
		fields: [compositeItems.inventoryAccountId],
		references: [accounts.id],
		relationName: "compositeItems_inventoryAccountId_accounts_id"
	}),
	manufacturer: one(manufacturers, {
		fields: [compositeItems.manufacturerId],
		references: [manufacturers.id]
	}),
	account_purchaseAccountId: one(accounts, {
		fields: [compositeItems.purchaseAccountId],
		references: [accounts.id],
		relationName: "compositeItems_purchaseAccountId_accounts_id"
	}),
	reorderTerm: one(reorderTerms, {
		fields: [compositeItems.reorderTermId],
		references: [reorderTerms.id]
	}),
	account_salesAccountId: one(accounts, {
		fields: [compositeItems.salesAccountId],
		references: [accounts.id],
		relationName: "compositeItems_salesAccountId_accounts_id"
	}),
	unit: one(units, {
		fields: [compositeItems.unitId],
		references: [units.id]
	}),
}));

export const vendorBankAccountsRelations = relations(vendorBankAccounts, ({one}) => ({
	vendor: one(vendors, {
		fields: [vendorBankAccounts.vendorId],
		references: [vendors.id]
	}),
}));

export const tdsSectionsRelations = relations(tdsSections, ({many}) => ({
	tdsRates: many(tdsRates),
}));

export const uqcRelations = relations(uqc, ({many}) => ({
	units: many(units),
}));

export const accountsRecurringJournalItemsRelations = relations(accountsRecurringJournalItems, ({one}) => ({
	account: one(accounts, {
		fields: [accountsRecurringJournalItems.accountId],
		references: [accounts.id]
	}),
	accountsRecurringJournal: one(accountsRecurringJournals, {
		fields: [accountsRecurringJournalItems.recurringJournalId],
		references: [accountsRecurringJournals.id]
	}),
}));

export const timezonesRelations = relations(timezones, ({one, many}) => ({
	countries: many(countries, {
		relationName: "countries_primaryTimezoneId_timezones_id"
	}),
	country: one(countries, {
		fields: [timezones.countryId],
		references: [countries.id],
		relationName: "timezones_countryId_countries_id"
	}),
}));

export const tdsGroupItemsRelations = relations(tdsGroupItems, ({one}) => ({
	tdsGroup: one(tdsGroups, {
		fields: [tdsGroupItems.tdsGroupId],
		references: [tdsGroups.id]
	}),
	tdsRate: one(tdsRates, {
		fields: [tdsGroupItems.tdsRateId],
		references: [tdsRates.id]
	}),
}));

export const tdsGroupsRelations = relations(tdsGroups, ({many}) => ({
	tdsGroupItems: many(tdsGroupItems),
}));

export const accountsJournalTemplateItemsRelations = relations(accountsJournalTemplateItems, ({one}) => ({
	account: one(accounts, {
		fields: [accountsJournalTemplateItems.accountId],
		references: [accounts.id]
	}),
	accountsJournalTemplate: one(accountsJournalTemplates, {
		fields: [accountsJournalTemplateItems.templateId],
		references: [accountsJournalTemplates.id]
	}),
}));

export const accountsJournalTemplatesRelations = relations(accountsJournalTemplates, ({many}) => ({
	accountsJournalTemplateItems: many(accountsJournalTemplateItems),
}));

export const accountsManualJournalItemsRelations = relations(accountsManualJournalItems, ({one, many}) => ({
	account: one(accounts, {
		fields: [accountsManualJournalItems.accountId],
		references: [accounts.id]
	}),
	accountsManualJournal: one(accountsManualJournals, {
		fields: [accountsManualJournalItems.manualJournalId],
		references: [accountsManualJournals.id]
	}),
	accountsManualJournalTagMappings: many(accountsManualJournalTagMappings),
}));

export const productOutletInventorySettingsRelations = relations(productOutletInventorySettings, ({one}) => ({
	product: one(products, {
		fields: [productOutletInventorySettings.productId],
		references: [products.id]
	}),
	reorderTerm: one(reorderTerms, {
		fields: [productOutletInventorySettings.reorderTermId],
		references: [reorderTerms.id]
	}),
}));

export const reorderTermsRelations = relations(reorderTerms, ({many}) => ({
	productOutletInventorySettings: many(productOutletInventorySettings),
	compositeItemOutletInventorySettings: many(compositeItemOutletInventorySettings),
	compositeItems: many(compositeItems),
}));

export const compositeItemOutletInventorySettingsRelations = relations(compositeItemOutletInventorySettings, ({one}) => ({
	compositeItem: one(compositeItems, {
		fields: [compositeItemOutletInventorySettings.compositeItemId],
		references: [compositeItems.id]
	}),
	reorderTerm: one(reorderTerms, {
		fields: [compositeItemOutletInventorySettings.reorderTermId],
		references: [reorderTerms.id]
	}),
}));

export const priceListItemsRelations = relations(priceListItems, ({one, many}) => ({
	priceList: one(priceLists, {
		fields: [priceListItems.priceListId],
		references: [priceLists.id]
	}),
	product: one(products, {
		fields: [priceListItems.productId],
		references: [products.id]
	}),
	priceListVolumeRanges: many(priceListVolumeRanges),
}));

export const itemVendorMappingsRelations = relations(itemVendorMappings, ({one}) => ({
	product: one(products, {
		fields: [itemVendorMappings.itemId],
		references: [products.id]
	}),
}));

export const priceListVolumeRangesRelations = relations(priceListVolumeRanges, ({one}) => ({
	priceListItem: one(priceListItems, {
		fields: [priceListVolumeRanges.priceListItemId],
		references: [priceListItems.id]
	}),
}));

export const customerContactPersonsRelations = relations(customerContactPersons, ({one}) => ({
	customer: one(customers, {
		fields: [customerContactPersons.customerId],
		references: [customers.id]
	}),
}));

export const currenciesRelations = relations(currencies, ({many}) => ({
	customers: many(customers),
}));

export const settingsBrandingRelations = relations(settingsBranding, ({one}) => ({
	organization: one(organization, {
		fields: [settingsBranding.orgId],
		references: [organization.id]
	}),
}));

export const settingsUserLocationAccessRelations = relations(settingsUserLocationAccess, ({one}) => ({
	organization: one(organization, {
		fields: [settingsUserLocationAccess.orgId],
		references: [organization.id]
	}),
}));

export const usersRelations = relations(users, ({one}) => ({
	organization: one(organization, {
		fields: [users.orgId],
		references: [organization.id]
	}),
}));

export const settingsRolesRelations = relations(settingsRoles, ({one}) => ({
	organization: one(organization, {
		fields: [settingsRoles.orgId],
		references: [organization.id]
	}),
}));

export const settingsBranchUserAccessRelations = relations(settingsBranchUserAccess, ({one}) => ({
	settingsBranch: one(settingsBranches, {
		fields: [settingsBranchUserAccess.branchId],
		references: [settingsBranches.id]
	}),
	organization: one(organization, {
		fields: [settingsBranchUserAccess.orgId],
		references: [organization.id]
	}),
}));

export const accountsManualJournalTagMappingsRelations = relations(accountsManualJournalTagMappings, ({one}) => ({
	accountsManualJournalItem: one(accountsManualJournalItems, {
		fields: [accountsManualJournalTagMappings.manualJournalItemId],
		references: [accountsManualJournalItems.id]
	}),
	accountsReportingTag: one(accountsReportingTags, {
		fields: [accountsManualJournalTagMappings.reportingTagId],
		references: [accountsReportingTags.id]
	}),
}));

export const accountsReportingTagsRelations = relations(accountsReportingTags, ({many}) => ({
	accountsManualJournalTagMappings: many(accountsManualJournalTagMappings),
}));