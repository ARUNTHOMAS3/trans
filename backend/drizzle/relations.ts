import { relations } from "drizzle-orm/relations";
import { products, batches, taxGroups, taxGroupTaxes, associateTaxes, countries, states, customers, salesPaymentLinks, brands, buyingRules, categories, accounts, manufacturers, vendors, racks, schedules, storageLocations, units, salesOrders, salesEwayBills, vendorContactPersons, compositeItemParts, compositeItems, vendorBankAccounts, tdsRates, tdsSections, uqc, accountsRecurringJournalItems, accountsRecurringJournals, salesPayments, timezones, tdsGroups, tdsGroupItems, accountsFiscalYears, accountsManualJournals, accountsJournalTemplateItems, accountsJournalTemplates, accountsManualJournalItems, accountTransactions, accountsManualJournalAttachments, organization, warehouses, contents, productContents, strengths, productWarehouseStocks, reorderTerms, priceLists, priceListItems, itemVendorMappings, priceListVolumeRanges, customerContactPersons, currencies, productWarehouseStockAdjustments, productOutletInventorySettings, compositeItemOutletInventorySettings, settingsBranding, settingsOutlets, settingsLocations, accountsManualJournalTagMappings, accountsReportingTags } from "./schema";

export const batchesRelations = relations(batches, ({one}) => ({
	product: one(products, {
		fields: [batches.productId],
		references: [products.id]
	}),
}));

export const productsRelations = relations(products, ({one, many}) => ({
	batches: many(batches),
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
	compositeItemParts: many(compositeItemParts),
	productContents: many(productContents),
	productWarehouseStocks: many(productWarehouseStocks),
	priceListItems: many(priceListItems),
	itemVendorMappings: many(itemVendorMappings),
	productWarehouseStockAdjustments: many(productWarehouseStockAdjustments),
	productOutletInventorySettings: many(productOutletInventorySettings),
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
	products: many(products),
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

export const accountsRelations = relations(accounts, ({one, many}) => ({
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
	tdsRates_payableAccountId: many(tdsRates, {
		relationName: "tdsRates_payableAccountId_accounts_id"
	}),
	tdsRates_receivableAccountId: many(tdsRates, {
		relationName: "tdsRates_receivableAccountId_accounts_id"
	}),
	accountsRecurringJournalItems: many(accountsRecurringJournalItems),
	accountsJournalTemplateItems: many(accountsJournalTemplateItems),
	accountsManualJournalItems: many(accountsManualJournalItems),
	accountTransactions: many(accountTransactions),
	compositeItems_inventoryAccountId: many(compositeItems, {
		relationName: "compositeItems_inventoryAccountId_accounts_id"
	}),
	compositeItems_purchaseAccountId: many(compositeItems, {
		relationName: "compositeItems_purchaseAccountId_accounts_id"
	}),
	compositeItems_salesAccountId: many(compositeItems, {
		relationName: "compositeItems_salesAccountId_accounts_id"
	}),
}));

export const manufacturersRelations = relations(manufacturers, ({many}) => ({
	products: many(products),
	compositeItems: many(compositeItems),
}));

export const vendorsRelations = relations(vendors, ({many}) => ({
	products: many(products),
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

export const salesEwayBillsRelations = relations(salesEwayBills, ({one}) => ({
	salesOrder: one(salesOrders, {
		fields: [salesEwayBills.saleId],
		references: [salesOrders.id]
	}),
}));

export const salesOrdersRelations = relations(salesOrders, ({one, many}) => ({
	salesEwayBills: many(salesEwayBills),
	customer: one(customers, {
		fields: [salesOrders.customerId],
		references: [customers.id]
	}),
}));

export const vendorContactPersonsRelations = relations(vendorContactPersons, ({one}) => ({
	vendor: one(vendors, {
		fields: [vendorContactPersons.vendorId],
		references: [vendors.id]
	}),
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
	compositeItemOutletInventorySettings: many(compositeItemOutletInventorySettings),
}));

export const vendorBankAccountsRelations = relations(vendorBankAccounts, ({one}) => ({
	vendor: one(vendors, {
		fields: [vendorBankAccounts.vendorId],
		references: [vendors.id]
	}),
}));

export const tdsRatesRelations = relations(tdsRates, ({one, many}) => ({
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

export const accountsRecurringJournalsRelations = relations(accountsRecurringJournals, ({many}) => ({
	accountsRecurringJournalItems: many(accountsRecurringJournalItems),
	accountsManualJournals: many(accountsManualJournals),
}));

export const salesPaymentsRelations = relations(salesPayments, ({one}) => ({
	customer: one(customers, {
		fields: [salesPayments.customerId],
		references: [customers.id]
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

export const accountsManualJournalsRelations = relations(accountsManualJournals, ({one, many}) => ({
	accountsFiscalYear: one(accountsFiscalYears, {
		fields: [accountsManualJournals.fiscalYearId],
		references: [accountsFiscalYears.id]
	}),
	accountsRecurringJournal: one(accountsRecurringJournals, {
		fields: [accountsManualJournals.recurringJournalId],
		references: [accountsRecurringJournals.id]
	}),
	accountsManualJournalItems: many(accountsManualJournalItems),
	accountsManualJournalAttachments: many(accountsManualJournalAttachments),
}));

export const accountsFiscalYearsRelations = relations(accountsFiscalYears, ({many}) => ({
	accountsManualJournals: many(accountsManualJournals),
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

export const warehousesRelations = relations(warehouses, ({one, many}) => ({
	organization: one(organization, {
		fields: [warehouses.orgId],
		references: [organization.id]
	}),
	productWarehouseStocks: many(productWarehouseStocks),
	productWarehouseStockAdjustments: many(productWarehouseStockAdjustments),
}));

export const organizationRelations = relations(organization, ({one, many}) => ({
	warehouses: many(warehouses),
	state: one(states, {
		fields: [organization.stateId],
		references: [states.id]
	}),
	settingsBrandings: many(settingsBranding),
	settingsOutlets: many(settingsOutlets),
	settingsLocations: many(settingsLocations),
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

export const productWarehouseStocksRelations = relations(productWarehouseStocks, ({one}) => ({
	product: one(products, {
		fields: [productWarehouseStocks.productId],
		references: [products.id]
	}),
	warehouse: one(warehouses, {
		fields: [productWarehouseStocks.warehouseId],
		references: [warehouses.id]
	}),
}));

export const reorderTermsRelations = relations(reorderTerms, ({many}) => ({
	compositeItems: many(compositeItems),
	productOutletInventorySettings: many(productOutletInventorySettings),
	compositeItemOutletInventorySettings: many(compositeItemOutletInventorySettings),
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

export const priceListsRelations = relations(priceLists, ({many}) => ({
	priceListItems: many(priceListItems),
	customers: many(customers),
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

export const productWarehouseStockAdjustmentsRelations = relations(productWarehouseStockAdjustments, ({one}) => ({
	product: one(products, {
		fields: [productWarehouseStockAdjustments.productId],
		references: [products.id]
	}),
	warehouse: one(warehouses, {
		fields: [productWarehouseStockAdjustments.warehouseId],
		references: [warehouses.id]
	}),
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

export const settingsBrandingRelations = relations(settingsBranding, ({one}) => ({
	organization: one(organization, {
		fields: [settingsBranding.orgId],
		references: [organization.id]
	}),
}));

export const settingsOutletsRelations = relations(settingsOutlets, ({one, many}) => ({
	organization: one(organization, {
		fields: [settingsOutlets.orgId],
		references: [organization.id]
	}),
	settingsLocations_outletId: many(settingsLocations, {
		relationName: "settingsLocations_outletId_settingsOutlets_id"
	}),
	settingsLocations_parentOutletId: many(settingsLocations, {
		relationName: "settingsLocations_parentOutletId_settingsOutlets_id"
	}),
}));

export const settingsLocationsRelations = relations(settingsLocations, ({one}) => ({
	organization: one(organization, {
		fields: [settingsLocations.orgId],
		references: [organization.id]
	}),
	settingsOutlet_outletId: one(settingsOutlets, {
		fields: [settingsLocations.outletId],
		references: [settingsOutlets.id],
		relationName: "settingsLocations_outletId_settingsOutlets_id"
	}),
	settingsOutlet_parentOutletId: one(settingsOutlets, {
		fields: [settingsLocations.parentOutletId],
		references: [settingsOutlets.id],
		relationName: "settingsLocations_parentOutletId_settingsOutlets_id"
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