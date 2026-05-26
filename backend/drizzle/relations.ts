import { relations } from "drizzle-orm/relations";
import { products, batchMaster, organisationBranchMaster, purchaseReceives, binMaster, warehouses, taxGroups, taxGroupRates, taxRates, batchStockLayers, vendors, invoiceMaster, transactionLocks, billItemBatches, billItems, purchaseReceiveItems, countries, states, customers, salesPaymentLinks, invoiceItems, purchaseReceiveItemBatches, purchaseOrderItems, accounts, purchaseOrders, inventoryAdjustments, inventoryAdjustmentValueItems, purchaseOrderAttachments, brands, buyingRules, categories, manufacturers, racks, reorderTerms, drugSchedules, storageConditions, units, salesOrders, paymentTerms, priceLists, tdsRates, inventoryAdjustmentAccountEntries, invoiceItemBatches, bills, billLandedCosts, fiscalYears, manualJournals, recurringJournals, journalNumberSettings, journalTemplates, invoiceSalesOrders, salesOrderAttachments, inventoryAdjustmentItems, invoiceShipments, inventoryShipments, manualJournalAttachments, accountTransactions, branchTransactionSeries, transactionSeries, contents, productContents, drugStrengths, branchUsers, users, lsgdLocalBodies, lsgdWards, vendorContactPersons, picklistBatchAllocation, picklistItems, carrier, lsgdDistricts, auditLogsArchive, salesPayments, invoiceAttachments, salesReturns, salesReturnReceives, compositeItemParts, compositeItems, vendorBankAccounts, auditLogs, tdsSections, uqc, timezones, tdsGroups, tdsGroupItems, recurringJournalItems, journalTemplateItems, inventoryAdjustmentAttachments, manualJournalItems, inventoryPackages, transferOrderMaster, branches, currencies, productVendorMappings, customerContactPersons, creditNotes, assembliesConstituencies, branding, zoneMaster, zoneLevels, transferOrderItems, inventoryPackageItems, picklistMaster, transactionalSequences, roles, organization, userBranchAccess, inventoryAdjustmentReasons, inventoryAdjustmentItemBatches, creditNoteItems, businessTypes, gstTreatments, gstinRegistrationTypes, branchUserAccess, reportingTags, creditNoteItemBatches, salesReturnReceiveItems, salesReturnItems, compositeItemBranchInventorySettings, productBranchInventorySettings, transferOrderSourceBatches, transferOrderDestinationBatches, transferOrderLogs, invoicePackages, salesReturnReceiveBatches, inventoryMoveOrders, inventoryMoveOrderItems, inventoryMoveOrderSourceBatches, inventoryMoveOrderDestinationBins, moveOrderAttachments, paymentReceivedAllocations, paymentsReceived, salesOrderItems, priceListItems, branchPriceListAssignments, priceListVolumeRanges, productEntitySettings, productBinMappings, manualJournalTagMappings, inventoryShipmentSalesOrders, inventoryShipmentPackages, inventoryPackageSalesOrders } from "./schema";

export const batchMasterRelations = relations(batchMaster, ({one, many}) => ({
	product: one(products, {
		fields: [batchMaster.productId],
		references: [products.id]
	}),
	batchStockLayers: many(batchStockLayers),
	billItemBatches: many(billItemBatches),
	inventoryAdjustmentValueItems: many(inventoryAdjustmentValueItems),
	invoiceItemBatches: many(invoiceItemBatches),
	inventoryAdjustmentItems: many(inventoryAdjustmentItems),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	creditNoteItemBatches: many(creditNoteItemBatches),
	transferOrderSourceBatches: many(transferOrderSourceBatches),
	salesReturnReceiveBatches: many(salesReturnReceiveBatches),
}));

export const productsRelations = relations(products, ({one, many}) => ({
	batchMasters: many(batchMaster),
	batchStockLayers: many(batchStockLayers),
	purchaseReceiveItems: many(purchaseReceiveItems),
	purchaseReceiveItemBatches: many(purchaseReceiveItemBatches),
	purchaseOrderItems: many(purchaseOrderItems),
	inventoryAdjustmentValueItems: many(inventoryAdjustmentValueItems),
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
	taxRate: one(taxRates, {
		fields: [products.interStateTaxId],
		references: [taxRates.id]
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
	reorderTerm: one(reorderTerms, {
		fields: [products.reorderTermId],
		references: [reorderTerms.id]
	}),
	account_salesAccountId: one(accounts, {
		fields: [products.salesAccountId],
		references: [accounts.id],
		relationName: "products_salesAccountId_accounts_id"
	}),
	drugSchedule: one(drugSchedules, {
		fields: [products.scheduleOfDrugId],
		references: [drugSchedules.id]
	}),
	storageCondition: one(storageConditions, {
		fields: [products.storageId],
		references: [storageConditions.id]
	}),
	unit: one(units, {
		fields: [products.unitId],
		references: [units.id]
	}),
	inventoryAdjustmentItems: many(inventoryAdjustmentItems),
	productContents: many(productContents),
	compositeItemParts: many(compositeItemParts),
	productVendorMappings: many(productVendorMappings),
	transferOrderItems: many(transferOrderItems),
	inventoryPackageItems: many(inventoryPackageItems),
	inventoryAdjustments: many(inventoryAdjustments),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	creditNoteItems: many(creditNoteItems),
	productBranchInventorySettings: many(productBranchInventorySettings),
	salesOrderItems: many(salesOrderItems),
	priceListItems: many(priceListItems),
	productEntitySettings: many(productEntitySettings),
	productBinMappings: many(productBinMappings),
	billItems: many(billItems),
}));

export const purchaseReceivesRelations = relations(purchaseReceives, ({one, many}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [purchaseReceives.entityId],
		references: [organisationBranchMaster.id]
	}),
	binMaster: one(binMaster, {
		fields: [purchaseReceives.transactionBinId],
		references: [binMaster.id]
	}),
	warehouse: one(warehouses, {
		fields: [purchaseReceives.warehouseId],
		references: [warehouses.id]
	}),
	purchaseReceiveItems: many(purchaseReceiveItems),
}));

export const organisationBranchMasterRelations = relations(organisationBranchMaster, ({many}) => ({
	purchaseReceives: many(purchaseReceives),
	invoiceMasters: many(invoiceMaster),
	transactionLocks: many(transactionLocks),
	purchaseReceiveItems: many(purchaseReceiveItems),
	salesPaymentLinks: many(salesPaymentLinks),
	purchaseReceiveItemBatches: many(purchaseReceiveItemBatches),
	purchaseOrderItems: many(purchaseOrderItems),
	inventoryAdjustmentValueItems: many(inventoryAdjustmentValueItems),
	accounts: many(accounts),
	salesOrders: many(salesOrders),
	inventoryAdjustmentAccountEntries: many(inventoryAdjustmentAccountEntries),
	manualJournals: many(manualJournals),
	journalNumberSettings: many(journalNumberSettings),
	journalTemplates: many(journalTemplates),
	salesOrderAttachments: many(salesOrderAttachments),
	inventoryAdjustmentItems: many(inventoryAdjustmentItems),
	manualJournalAttachments: many(manualJournalAttachments),
	accountTransactions: many(accountTransactions),
	branchTransactionSeries: many(branchTransactionSeries),
	branchUsers: many(branchUsers),
	recurringJournals: many(recurringJournals),
	reorderTerms: many(reorderTerms),
	vendors: many(vendors),
	purchaseOrders: many(purchaseOrders),
	auditLogsArchives: many(auditLogsArchive),
	salesPayments: many(salesPayments),
	auditLogs: many(auditLogs),
	fiscalYears: many(fiscalYears),
	journalTemplateItems: many(journalTemplateItems),
	inventoryAdjustmentAttachments: many(inventoryAdjustmentAttachments),
	manualJournalItems: many(manualJournalItems),
	inventoryPackages: many(inventoryPackages),
	transferOrderMasters: many(transferOrderMaster),
	customers: many(customers),
	customerContactPersons: many(customerContactPersons),
	creditNotes: many(creditNotes),
	brandings: many(branding),
	users: many(users),
	inventoryPackageItems: many(inventoryPackageItems),
	transactionalSequences: many(transactionalSequences),
	roles: many(roles),
	transactionSeries: many(transactionSeries),
	userBranchAccesses: many(userBranchAccess),
	inventoryAdjustments: many(inventoryAdjustments),
	inventoryAdjustmentReasons: many(inventoryAdjustmentReasons),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	branches: many(branches),
	branchUserAccesses: many(branchUserAccess),
	reportingTags: many(reportingTags),
	organizations: many(organization),
	compositeItemBranchInventorySettings: many(compositeItemBranchInventorySettings),
	productBranchInventorySettings: many(productBranchInventorySettings),
	warehouses: many(warehouses),
	inventoryShipments: many(inventoryShipments),
	salesOrderItems: many(salesOrderItems),
	priceLists_createdByEntityId: many(priceLists, {
		relationName: "priceLists_createdByEntityId_organisationBranchMaster_id"
	}),
	priceLists_entityId: many(priceLists, {
		relationName: "priceLists_entityId_organisationBranchMaster_id"
	}),
	branchPriceListAssignments: many(branchPriceListAssignments),
	bills: many(bills),
}));

export const binMasterRelations = relations(binMaster, ({one, many}) => ({
	purchaseReceives: many(purchaseReceives),
	batchStockLayers: many(batchStockLayers),
	billItemBatches: many(billItemBatches),
	purchaseReceiveItems: many(purchaseReceiveItems),
	purchaseReceiveItemBatches: many(purchaseReceiveItemBatches),
	picklistBatchAllocations: many(picklistBatchAllocation),
	warehouse: one(warehouses, {
		fields: [binMaster.warehouseId],
		references: [warehouses.id]
	}),
	zoneMaster: one(zoneMaster, {
		fields: [binMaster.zoneId],
		references: [zoneMaster.id]
	}),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	creditNoteItemBatches: many(creditNoteItemBatches),
	transferOrderSourceBatches: many(transferOrderSourceBatches),
	transferOrderDestinationBatches: many(transferOrderDestinationBatches),
	salesReturnReceiveBatches: many(salesReturnReceiveBatches),
}));

export const warehousesRelations = relations(warehouses, ({one, many}) => ({
	purchaseReceives: many(purchaseReceives),
	batchStockLayers: many(batchStockLayers),
	billItemBatches: many(billItemBatches),
	purchaseReceiveItems: many(purchaseReceiveItems),
	purchaseReceiveItemBatches: many(purchaseReceiveItemBatches),
	salesOrders: many(salesOrders),
	picklistBatchAllocations: many(picklistBatchAllocation),
	purchaseOrders_deliveryWarehouseId: many(purchaseOrders, {
		relationName: "purchaseOrders_deliveryWarehouseId_warehouses_id"
	}),
	purchaseOrders_warehouseId: many(purchaseOrders, {
		relationName: "purchaseOrders_warehouseId_warehouses_id"
	}),
	salesReturnReceives: many(salesReturnReceives),
	transferOrderMasters_destinationWarehouseId: many(transferOrderMaster, {
		relationName: "transferOrderMaster_destinationWarehouseId_warehouses_id"
	}),
	transferOrderMasters_sourceWarehouseId: many(transferOrderMaster, {
		relationName: "transferOrderMaster_sourceWarehouseId_warehouses_id"
	}),
	creditNotes: many(creditNotes),
	users: many(users),
	binMasters: many(binMaster),
	inventoryAdjustments: many(inventoryAdjustments),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	creditNoteItemBatches: many(creditNoteItemBatches),
	assembliesConstituency: one(assembliesConstituencies, {
		fields: [warehouses.assemblyId],
		references: [assembliesConstituencies.id]
	}),
	customer: one(customers, {
		fields: [warehouses.customerId],
		references: [customers.id]
	}),
	lsgdDistrict: one(lsgdDistricts, {
		fields: [warehouses.districtId],
		references: [lsgdDistricts.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [warehouses.entityId],
		references: [organisationBranchMaster.id]
	}),
	lsgdLocalBody: one(lsgdLocalBodies, {
		fields: [warehouses.localBodyId],
		references: [lsgdLocalBodies.id]
	}),
	branch: one(branches, {
		fields: [warehouses.sourceBranchId],
		references: [branches.id]
	}),
	vendor: one(vendors, {
		fields: [warehouses.vendorId],
		references: [vendors.id]
	}),
	lsgdWard: one(lsgdWards, {
		fields: [warehouses.wardId],
		references: [lsgdWards.id]
	}),
	transferOrderSourceBatches: many(transferOrderSourceBatches),
	transferOrderDestinationBatches: many(transferOrderDestinationBatches),
	salesReturnReceiveBatches: many(salesReturnReceiveBatches),
	salesOrderItems: many(salesOrderItems),
	bills: many(bills),
}));

export const taxGroupRatesRelations = relations(taxGroupRates, ({one}) => ({
	taxGroup: one(taxGroups, {
		fields: [taxGroupRates.taxGroupId],
		references: [taxGroups.id]
	}),
	taxRate: one(taxRates, {
		fields: [taxGroupRates.taxId],
		references: [taxRates.id]
	}),
}));

export const taxGroupsRelations = relations(taxGroups, ({many}) => ({
	taxGroupRates: many(taxGroupRates),
	products: many(products),
}));

export const taxRatesRelations = relations(taxRates, ({many}) => ({
	taxGroupRates: many(taxGroupRates),
	products: many(products),
	compositeItems_interStateTaxId: many(compositeItems, {
		relationName: "compositeItems_interStateTaxId_taxRates_id"
	}),
	compositeItems_intraStateTaxId: many(compositeItems, {
		relationName: "compositeItems_intraStateTaxId_taxRates_id"
	}),
	salesOrderItems: many(salesOrderItems),
}));

export const batchStockLayersRelations = relations(batchStockLayers, ({one, many}) => ({
	binMaster: one(binMaster, {
		fields: [batchStockLayers.binId],
		references: [binMaster.id]
	}),
	product: one(products, {
		fields: [batchStockLayers.productId],
		references: [products.id]
	}),
	vendor: one(vendors, {
		fields: [batchStockLayers.vendorId],
		references: [vendors.id]
	}),
	warehouse: one(warehouses, {
		fields: [batchStockLayers.warehouseId],
		references: [warehouses.id]
	}),
	batchMaster: one(batchMaster, {
		fields: [batchStockLayers.batchId],
		references: [batchMaster.id]
	}),
	billItemBatches: many(billItemBatches),
	invoiceItemBatches: many(invoiceItemBatches),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	creditNoteItemBatches: many(creditNoteItemBatches),
	transferOrderSourceBatches: many(transferOrderSourceBatches),
	salesReturnReceiveBatches: many(salesReturnReceiveBatches),
}));

export const vendorsRelations = relations(vendors, ({one, many}) => ({
	batchStockLayers: many(batchStockLayers),
	products: many(products),
	vendorContactPersons: many(vendorContactPersons),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [vendors.entityId],
		references: [organisationBranchMaster.id]
	}),
	purchaseOrders: many(purchaseOrders),
	vendorBankAccounts: many(vendorBankAccounts),
	warehouses: many(warehouses),
	bills: many(bills),
	productEntitySettings: many(productEntitySettings),
}));

export const invoiceMasterRelations = relations(invoiceMaster, ({one, many}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [invoiceMaster.entityId],
		references: [organisationBranchMaster.id]
	}),
	invoiceItems: many(invoiceItems),
	invoiceSalesOrders: many(invoiceSalesOrders),
	invoiceShipments: many(invoiceShipments),
	invoiceAttachments: many(invoiceAttachments),
	invoicePackages: many(invoicePackages),
	paymentReceivedAllocations: many(paymentReceivedAllocations),
}));

export const transactionLocksRelations = relations(transactionLocks, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [transactionLocks.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const billItemBatchesRelations = relations(billItemBatches, ({one}) => ({
	batchMaster: one(batchMaster, {
		fields: [billItemBatches.batchId],
		references: [batchMaster.id]
	}),
	billItem: one(billItems, {
		fields: [billItemBatches.billItemId],
		references: [billItems.id]
	}),
	binMaster: one(binMaster, {
		fields: [billItemBatches.binId],
		references: [binMaster.id]
	}),
	batchStockLayer: one(batchStockLayers, {
		fields: [billItemBatches.layerId],
		references: [batchStockLayers.id]
	}),
	warehouse: one(warehouses, {
		fields: [billItemBatches.warehouseId],
		references: [warehouses.id]
	}),
}));

export const billItemsRelations = relations(billItems, ({one, many}) => ({
	billItemBatches: many(billItemBatches),
	bill: one(bills, {
		fields: [billItems.billId],
		references: [bills.id]
	}),
	product: one(products, {
		fields: [billItems.productId],
		references: [products.id]
	}),
}));

export const purchaseReceiveItemsRelations = relations(purchaseReceiveItems, ({one, many}) => ({
	binMaster: one(binMaster, {
		fields: [purchaseReceiveItems.binId],
		references: [binMaster.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [purchaseReceiveItems.entityId],
		references: [organisationBranchMaster.id]
	}),
	product: one(products, {
		fields: [purchaseReceiveItems.itemId],
		references: [products.id]
	}),
	purchaseReceive: one(purchaseReceives, {
		fields: [purchaseReceiveItems.purchaseReceiveId],
		references: [purchaseReceives.id]
	}),
	warehouse: one(warehouses, {
		fields: [purchaseReceiveItems.warehouseId],
		references: [warehouses.id]
	}),
	purchaseReceiveItemBatches: many(purchaseReceiveItemBatches),
}));

export const statesRelations = relations(states, ({one, many}) => ({
	country: one(countries, {
		fields: [states.stateId],
		references: [countries.id]
	}),
	lsgdDistricts: many(lsgdDistricts),
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
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [salesPaymentLinks.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const customersRelations = relations(customers, ({one, many}) => ({
	salesPaymentLinks: many(salesPaymentLinks),
	salesOrders: many(salesOrders),
	purchaseOrders: many(purchaseOrders),
	salesPayments: many(salesPayments),
	inventoryPackages: many(inventoryPackages),
	branch: one(branches, {
		fields: [customers.associatedBranchId],
		references: [branches.id]
	}),
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
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [customers.entityId],
		references: [organisationBranchMaster.id]
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
	customerContactPersons: many(customerContactPersons),
	creditNotes: many(creditNotes),
	warehouses: many(warehouses),
	inventoryShipments: many(inventoryShipments),
	salesReturns: many(salesReturns),
	paymentsReceiveds: many(paymentsReceived),
}));

export const invoiceItemsRelations = relations(invoiceItems, ({one, many}) => ({
	invoiceMaster: one(invoiceMaster, {
		fields: [invoiceItems.invoiceId],
		references: [invoiceMaster.id]
	}),
	invoiceItemBatches: many(invoiceItemBatches),
}));

export const purchaseReceiveItemBatchesRelations = relations(purchaseReceiveItemBatches, ({one}) => ({
	binMaster: one(binMaster, {
		fields: [purchaseReceiveItemBatches.binId],
		references: [binMaster.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [purchaseReceiveItemBatches.entityId],
		references: [organisationBranchMaster.id]
	}),
	product: one(products, {
		fields: [purchaseReceiveItemBatches.productId],
		references: [products.id]
	}),
	purchaseReceiveItem: one(purchaseReceiveItems, {
		fields: [purchaseReceiveItemBatches.purchaseReceiveItemId],
		references: [purchaseReceiveItems.id]
	}),
	warehouse: one(warehouses, {
		fields: [purchaseReceiveItemBatches.warehouseId],
		references: [warehouses.id]
	}),
}));

export const purchaseOrderItemsRelations = relations(purchaseOrderItems, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [purchaseOrderItems.entityId],
		references: [organisationBranchMaster.id]
	}),
	account: one(accounts, {
		fields: [purchaseOrderItems.accountId],
		references: [accounts.id]
	}),
	product: one(products, {
		fields: [purchaseOrderItems.productId],
		references: [products.id]
	}),
	purchaseOrder: one(purchaseOrders, {
		fields: [purchaseOrderItems.purchaseOrderId],
		references: [purchaseOrders.id]
	}),
}));

export const accountsRelations = relations(accounts, ({one, many}) => ({
	purchaseOrderItems: many(purchaseOrderItems),
	products_inventoryAccountId: many(products, {
		relationName: "products_inventoryAccountId_accounts_id"
	}),
	products_purchaseAccountId: many(products, {
		relationName: "products_purchaseAccountId_accounts_id"
	}),
	products_salesAccountId: many(products, {
		relationName: "products_salesAccountId_accounts_id"
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [accounts.entityId],
		references: [organisationBranchMaster.id]
	}),
	account: one(accounts, {
		fields: [accounts.parentId],
		references: [accounts.id],
		relationName: "accounts_parentId_accounts_id"
	}),
	accounts: many(accounts, {
		relationName: "accounts_parentId_accounts_id"
	}),
	inventoryAdjustmentAccountEntries: many(inventoryAdjustmentAccountEntries),
	accountTransactions: many(accountTransactions),
	purchaseOrders: many(purchaseOrders),
	tdsRates_payableAccountId: many(tdsRates, {
		relationName: "tdsRates_payableAccountId_accounts_id"
	}),
	tdsRates_receivableAccountId: many(tdsRates, {
		relationName: "tdsRates_receivableAccountId_accounts_id"
	}),
	recurringJournalItems: many(recurringJournalItems),
	journalTemplateItems: many(journalTemplateItems),
	manualJournalItems: many(manualJournalItems),
	compositeItems_inventoryAccountId: many(compositeItems, {
		relationName: "compositeItems_inventoryAccountId_accounts_id"
	}),
	compositeItems_purchaseAccountId: many(compositeItems, {
		relationName: "compositeItems_purchaseAccountId_accounts_id"
	}),
	compositeItems_salesAccountId: many(compositeItems, {
		relationName: "compositeItems_salesAccountId_accounts_id"
	}),
	inventoryAdjustments: many(inventoryAdjustments),
	creditNoteItems: many(creditNoteItems),
	branches: many(branches),
	salesOrderItems: many(salesOrderItems),
}));

export const purchaseOrdersRelations = relations(purchaseOrders, ({one, many}) => ({
	purchaseOrderItems: many(purchaseOrderItems),
	purchaseOrderAttachments: many(purchaseOrderAttachments),
	account: one(accounts, {
		fields: [purchaseOrders.discountAccountId],
		references: [accounts.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [purchaseOrders.entityId],
		references: [organisationBranchMaster.id]
	}),
	customer: one(customers, {
		fields: [purchaseOrders.deliveryCustomerId],
		references: [customers.id]
	}),
	warehouse_deliveryWarehouseId: one(warehouses, {
		fields: [purchaseOrders.deliveryWarehouseId],
		references: [warehouses.id],
		relationName: "purchaseOrders_deliveryWarehouseId_warehouses_id"
	}),
	paymentTerm: one(paymentTerms, {
		fields: [purchaseOrders.paymentTermsId],
		references: [paymentTerms.id]
	}),
	carrier: one(carrier, {
		fields: [purchaseOrders.shipmentPreferenceId],
		references: [carrier.id]
	}),
	tdsRate: one(tdsRates, {
		fields: [purchaseOrders.tdsId],
		references: [tdsRates.id]
	}),
	vendor: one(vendors, {
		fields: [purchaseOrders.vendorId],
		references: [vendors.id]
	}),
	warehouse_warehouseId: one(warehouses, {
		fields: [purchaseOrders.warehouseId],
		references: [warehouses.id],
		relationName: "purchaseOrders_warehouseId_warehouses_id"
	}),
}));

export const inventoryAdjustmentValueItemsRelations = relations(inventoryAdjustmentValueItems, ({one}) => ({
	inventoryAdjustment: one(inventoryAdjustments, {
		fields: [inventoryAdjustmentValueItems.adjustmentId],
		references: [inventoryAdjustments.id]
	}),
	batchMaster: one(batchMaster, {
		fields: [inventoryAdjustmentValueItems.batchId],
		references: [batchMaster.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryAdjustmentValueItems.entityId],
		references: [organisationBranchMaster.id]
	}),
	product: one(products, {
		fields: [inventoryAdjustmentValueItems.productId],
		references: [products.id]
	}),
}));

export const inventoryAdjustmentsRelations = relations(inventoryAdjustments, ({one, many}) => ({
	inventoryAdjustmentValueItems: many(inventoryAdjustmentValueItems),
	inventoryAdjustmentAccountEntries: many(inventoryAdjustmentAccountEntries),
	inventoryAdjustmentItems: many(inventoryAdjustmentItems),
	inventoryAdjustmentAttachments: many(inventoryAdjustmentAttachments),
	inventoryAdjustmentReason: one(inventoryAdjustmentReasons, {
		fields: [inventoryAdjustments.reasonId],
		references: [inventoryAdjustmentReasons.id]
	}),
	account: one(accounts, {
		fields: [inventoryAdjustments.accountId],
		references: [accounts.id]
	}),
	user_adjustedBy: one(users, {
		fields: [inventoryAdjustments.adjustedBy],
		references: [users.id],
		relationName: "inventoryAdjustments_adjustedBy_users_id"
	}),
	user_approvedBy: one(users, {
		fields: [inventoryAdjustments.approvedBy],
		references: [users.id],
		relationName: "inventoryAdjustments_approvedBy_users_id"
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryAdjustments.entityId],
		references: [organisationBranchMaster.id]
	}),
	product: one(products, {
		fields: [inventoryAdjustments.productId],
		references: [products.id]
	}),
	warehouse: one(warehouses, {
		fields: [inventoryAdjustments.warehouseId],
		references: [warehouses.id]
	}),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
}));

export const purchaseOrderAttachmentsRelations = relations(purchaseOrderAttachments, ({one}) => ({
	purchaseOrder: one(purchaseOrders, {
		fields: [purchaseOrderAttachments.purchaseOrderId],
		references: [purchaseOrders.id]
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

export const racksRelations = relations(racks, ({many}) => ({
	products: many(products),
}));

export const reorderTermsRelations = relations(reorderTerms, ({one, many}) => ({
	products: many(products),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [reorderTerms.entityId],
		references: [organisationBranchMaster.id]
	}),
	compositeItems: many(compositeItems),
	compositeItemBranchInventorySettings: many(compositeItemBranchInventorySettings),
	productBranchInventorySettings: many(productBranchInventorySettings),
	productEntitySettings: many(productEntitySettings),
}));

export const drugSchedulesRelations = relations(drugSchedules, ({many}) => ({
	products: many(products),
	productContents: many(productContents),
}));

export const storageConditionsRelations = relations(storageConditions, ({many}) => ({
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

export const salesOrdersRelations = relations(salesOrders, ({one, many}) => ({
	customer: one(customers, {
		fields: [salesOrders.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [salesOrders.entityId],
		references: [organisationBranchMaster.id]
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
	invoiceSalesOrders: many(invoiceSalesOrders),
	salesOrderAttachments: many(salesOrderAttachments),
	salesOrderItems: many(salesOrderItems),
	inventoryShipmentSalesOrders: many(inventoryShipmentSalesOrders),
}));

export const paymentTermsRelations = relations(paymentTerms, ({many}) => ({
	salesOrders: many(salesOrders),
	purchaseOrders: many(purchaseOrders),
}));

export const priceListsRelations = relations(priceLists, ({one, many}) => ({
	salesOrders: many(salesOrders),
	customers: many(customers),
	creditNotes: many(creditNotes),
	priceListItems: many(priceListItems),
	organisationBranchMaster_createdByEntityId: one(organisationBranchMaster, {
		fields: [priceLists.createdByEntityId],
		references: [organisationBranchMaster.id],
		relationName: "priceLists_createdByEntityId_organisationBranchMaster_id"
	}),
	organisationBranchMaster_entityId: one(organisationBranchMaster, {
		fields: [priceLists.entityId],
		references: [organisationBranchMaster.id],
		relationName: "priceLists_entityId_organisationBranchMaster_id"
	}),
	branchPriceListAssignments: many(branchPriceListAssignments),
}));

export const tdsRatesRelations = relations(tdsRates, ({one, many}) => ({
	salesOrders: many(salesOrders),
	purchaseOrders: many(purchaseOrders),
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

export const inventoryAdjustmentAccountEntriesRelations = relations(inventoryAdjustmentAccountEntries, ({one}) => ({
	account: one(accounts, {
		fields: [inventoryAdjustmentAccountEntries.accountId],
		references: [accounts.id]
	}),
	inventoryAdjustment: one(inventoryAdjustments, {
		fields: [inventoryAdjustmentAccountEntries.adjustmentId],
		references: [inventoryAdjustments.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryAdjustmentAccountEntries.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const invoiceItemBatchesRelations = relations(invoiceItemBatches, ({one}) => ({
	batchMaster: one(batchMaster, {
		fields: [invoiceItemBatches.batchId],
		references: [batchMaster.id]
	}),
	invoiceItem: one(invoiceItems, {
		fields: [invoiceItemBatches.invoiceItemId],
		references: [invoiceItems.id]
	}),
	batchStockLayer: one(batchStockLayers, {
		fields: [invoiceItemBatches.layerId],
		references: [batchStockLayers.id]
	}),
}));

export const billLandedCostsRelations = relations(billLandedCosts, ({one}) => ({
	bill: one(bills, {
		fields: [billLandedCosts.billId],
		references: [bills.id]
	}),
}));

export const billsRelations = relations(bills, ({one, many}) => ({
	billLandedCosts: many(billLandedCosts),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [bills.entityId],
		references: [organisationBranchMaster.id]
	}),
	vendor: one(vendors, {
		fields: [bills.vendorId],
		references: [vendors.id]
	}),
	warehouse: one(warehouses, {
		fields: [bills.warehouseId],
		references: [warehouses.id]
	}),
	billItems: many(billItems),
}));

export const manualJournalsRelations = relations(manualJournals, ({one, many}) => ({
	fiscalYear: one(fiscalYears, {
		fields: [manualJournals.fiscalYearId],
		references: [fiscalYears.id]
	}),
	recurringJournal: one(recurringJournals, {
		fields: [manualJournals.recurringJournalId],
		references: [recurringJournals.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [manualJournals.entityId],
		references: [organisationBranchMaster.id]
	}),
	manualJournalAttachments: many(manualJournalAttachments),
	manualJournalItems: many(manualJournalItems),
}));

export const fiscalYearsRelations = relations(fiscalYears, ({one, many}) => ({
	manualJournals: many(manualJournals),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [fiscalYears.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const recurringJournalsRelations = relations(recurringJournals, ({one, many}) => ({
	manualJournals: many(manualJournals),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [recurringJournals.entityId],
		references: [organisationBranchMaster.id]
	}),
	recurringJournalItems: many(recurringJournalItems),
}));

export const journalNumberSettingsRelations = relations(journalNumberSettings, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [journalNumberSettings.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const journalTemplatesRelations = relations(journalTemplates, ({one, many}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [journalTemplates.entityId],
		references: [organisationBranchMaster.id]
	}),
	journalTemplateItems: many(journalTemplateItems),
}));

export const invoiceSalesOrdersRelations = relations(invoiceSalesOrders, ({one}) => ({
	invoiceMaster: one(invoiceMaster, {
		fields: [invoiceSalesOrders.invoiceId],
		references: [invoiceMaster.id]
	}),
	salesOrder: one(salesOrders, {
		fields: [invoiceSalesOrders.salesOrderId],
		references: [salesOrders.id]
	}),
}));

export const salesOrderAttachmentsRelations = relations(salesOrderAttachments, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [salesOrderAttachments.entityId],
		references: [organisationBranchMaster.id]
	}),
	salesOrder: one(salesOrders, {
		fields: [salesOrderAttachments.salesOrderId],
		references: [salesOrders.id]
	}),
}));

export const inventoryAdjustmentItemsRelations = relations(inventoryAdjustmentItems, ({one, many}) => ({
	inventoryAdjustment: one(inventoryAdjustments, {
		fields: [inventoryAdjustmentItems.adjustmentId],
		references: [inventoryAdjustments.id]
	}),
	batchMaster: one(batchMaster, {
		fields: [inventoryAdjustmentItems.batchId],
		references: [batchMaster.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryAdjustmentItems.entityId],
		references: [organisationBranchMaster.id]
	}),
	product: one(products, {
		fields: [inventoryAdjustmentItems.productId],
		references: [products.id]
	}),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
}));

export const invoiceShipmentsRelations = relations(invoiceShipments, ({one}) => ({
	invoiceMaster: one(invoiceMaster, {
		fields: [invoiceShipments.invoiceId],
		references: [invoiceMaster.id]
	}),
	inventoryShipment: one(inventoryShipments, {
		fields: [invoiceShipments.shipmentId],
		references: [inventoryShipments.id]
	}),
}));

export const inventoryShipmentsRelations = relations(inventoryShipments, ({one, many}) => ({
	invoiceShipments: many(invoiceShipments),
	customer: one(customers, {
		fields: [inventoryShipments.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryShipments.entityId],
		references: [organisationBranchMaster.id]
	}),
	inventoryShipmentSalesOrders: many(inventoryShipmentSalesOrders),
	inventoryShipmentPackages: many(inventoryShipmentPackages),
}));

export const manualJournalAttachmentsRelations = relations(manualJournalAttachments, ({one}) => ({
	manualJournal: one(manualJournals, {
		fields: [manualJournalAttachments.manualJournalId],
		references: [manualJournals.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [manualJournalAttachments.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const accountTransactionsRelations = relations(accountTransactions, ({one}) => ({
	account: one(accounts, {
		fields: [accountTransactions.accountId],
		references: [accounts.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [accountTransactions.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const branchTransactionSeriesRelations = relations(branchTransactionSeries, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [branchTransactionSeries.entityId],
		references: [organisationBranchMaster.id]
	}),
	transactionSery: one(transactionSeries, {
		fields: [branchTransactionSeries.transactionSeriesId],
		references: [transactionSeries.id]
	}),
}));

export const transactionSeriesRelations = relations(transactionSeries, ({one, many}) => ({
	branchTransactionSeries: many(branchTransactionSeries),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [transactionSeries.entityId],
		references: [organisationBranchMaster.id]
	}),
	branches: many(branches),
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
	drugSchedule: one(drugSchedules, {
		fields: [productContents.sheduleId],
		references: [drugSchedules.id]
	}),
	drugStrength: one(drugStrengths, {
		fields: [productContents.strengthId],
		references: [drugStrengths.id]
	}),
}));

export const contentsRelations = relations(contents, ({many}) => ({
	productContents: many(productContents),
}));

export const drugStrengthsRelations = relations(drugStrengths, ({many}) => ({
	productContents: many(productContents),
}));

export const branchUsersRelations = relations(branchUsers, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [branchUsers.entityId],
		references: [organisationBranchMaster.id]
	}),
	user: one(users, {
		fields: [branchUsers.userId],
		references: [users.id]
	}),
}));

export const usersRelations = relations(users, ({one, many}) => ({
	branchUsers: many(branchUsers),
	inventoryAdjustmentAttachments: many(inventoryAdjustmentAttachments),
	warehouse: one(warehouses, {
		fields: [users.defaultWarehouseId],
		references: [warehouses.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [users.entityId],
		references: [organisationBranchMaster.id]
	}),
	inventoryAdjustments_adjustedBy: many(inventoryAdjustments, {
		relationName: "inventoryAdjustments_adjustedBy_users_id"
	}),
	inventoryAdjustments_approvedBy: many(inventoryAdjustments, {
		relationName: "inventoryAdjustments_approvedBy_users_id"
	}),
	branchUserAccesses: many(branchUserAccess),
}));

export const lsgdWardsRelations = relations(lsgdWards, ({one, many}) => ({
	lsgdLocalBody: one(lsgdLocalBodies, {
		fields: [lsgdWards.localBodyId],
		references: [lsgdLocalBodies.id]
	}),
	branches: many(branches),
	organizations_paymentStubWardId: many(organization, {
		relationName: "organization_paymentStubWardId_lsgdWards_id"
	}),
	organizations_wardId: many(organization, {
		relationName: "organization_wardId_lsgdWards_id"
	}),
	warehouses: many(warehouses),
}));

export const lsgdLocalBodiesRelations = relations(lsgdLocalBodies, ({one, many}) => ({
	lsgdWards: many(lsgdWards),
	lsgdDistrict: one(lsgdDistricts, {
		fields: [lsgdLocalBodies.districtId],
		references: [lsgdDistricts.id]
	}),
	branches: many(branches),
	organizations_localBodyId: many(organization, {
		relationName: "organization_localBodyId_lsgdLocalBodies_id"
	}),
	organizations_paymentStubLocalBodyId: many(organization, {
		relationName: "organization_paymentStubLocalBodyId_lsgdLocalBodies_id"
	}),
	warehouses: many(warehouses),
}));

export const vendorContactPersonsRelations = relations(vendorContactPersons, ({one}) => ({
	vendor: one(vendors, {
		fields: [vendorContactPersons.vendorId],
		references: [vendors.id]
	}),
}));

export const picklistBatchAllocationRelations = relations(picklistBatchAllocation, ({one}) => ({
	binMaster: one(binMaster, {
		fields: [picklistBatchAllocation.binId],
		references: [binMaster.id]
	}),
	picklistItem: one(picklistItems, {
		fields: [picklistBatchAllocation.picklistItemId],
		references: [picklistItems.id]
	}),
	warehouse: one(warehouses, {
		fields: [picklistBatchAllocation.warehouseId],
		references: [warehouses.id]
	}),
}));

export const picklistItemsRelations = relations(picklistItems, ({many}) => ({
	picklistBatchAllocations: many(picklistBatchAllocation),
}));

export const carrierRelations = relations(carrier, ({many}) => ({
	purchaseOrders: many(purchaseOrders),
}));

export const lsgdDistrictsRelations = relations(lsgdDistricts, ({one, many}) => ({
	state: one(states, {
		fields: [lsgdDistricts.stateId],
		references: [states.id]
	}),
	assembliesConstituencies: many(assembliesConstituencies),
	lsgdLocalBodies: many(lsgdLocalBodies),
	branches: many(branches),
	organizations_districtId: many(organization, {
		relationName: "organization_districtId_lsgdDistricts_id"
	}),
	organizations_paymentStubDistrictId: many(organization, {
		relationName: "organization_paymentStubDistrictId_lsgdDistricts_id"
	}),
	warehouses: many(warehouses),
}));

export const auditLogsArchiveRelations = relations(auditLogsArchive, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [auditLogsArchive.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const salesPaymentsRelations = relations(salesPayments, ({one}) => ({
	customer: one(customers, {
		fields: [salesPayments.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [salesPayments.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const invoiceAttachmentsRelations = relations(invoiceAttachments, ({one}) => ({
	invoiceMaster: one(invoiceMaster, {
		fields: [invoiceAttachments.invoiceId],
		references: [invoiceMaster.id]
	}),
}));

export const salesReturnReceivesRelations = relations(salesReturnReceives, ({one, many}) => ({
	salesReturn: one(salesReturns, {
		fields: [salesReturnReceives.salesReturnId],
		references: [salesReturns.id]
	}),
	warehouse: one(warehouses, {
		fields: [salesReturnReceives.warehouseId],
		references: [warehouses.id]
	}),
	salesReturnReceiveItems: many(salesReturnReceiveItems),
}));

export const salesReturnsRelations = relations(salesReturns, ({one, many}) => ({
	salesReturnReceives: many(salesReturnReceives),
	customer: one(customers, {
		fields: [salesReturns.customerId],
		references: [customers.id]
	}),
	salesReturnItems: many(salesReturnItems),
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
	taxRate_interStateTaxId: one(taxRates, {
		fields: [compositeItems.interStateTaxId],
		references: [taxRates.id],
		relationName: "compositeItems_interStateTaxId_taxRates_id"
	}),
	taxRate_intraStateTaxId: one(taxRates, {
		fields: [compositeItems.intraStateTaxId],
		references: [taxRates.id],
		relationName: "compositeItems_intraStateTaxId_taxRates_id"
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
	compositeItemBranchInventorySettings: many(compositeItemBranchInventorySettings),
}));

export const vendorBankAccountsRelations = relations(vendorBankAccounts, ({one}) => ({
	vendor: one(vendors, {
		fields: [vendorBankAccounts.vendorId],
		references: [vendors.id]
	}),
}));

export const auditLogsRelations = relations(auditLogs, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [auditLogs.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const tdsSectionsRelations = relations(tdsSections, ({many}) => ({
	tdsRates: many(tdsRates),
}));

export const uqcRelations = relations(uqc, ({many}) => ({
	units: many(units),
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

export const recurringJournalItemsRelations = relations(recurringJournalItems, ({one}) => ({
	account: one(accounts, {
		fields: [recurringJournalItems.accountId],
		references: [accounts.id]
	}),
	recurringJournal: one(recurringJournals, {
		fields: [recurringJournalItems.recurringJournalId],
		references: [recurringJournals.id]
	}),
}));

export const journalTemplateItemsRelations = relations(journalTemplateItems, ({one}) => ({
	account: one(accounts, {
		fields: [journalTemplateItems.accountId],
		references: [accounts.id]
	}),
	journalTemplate: one(journalTemplates, {
		fields: [journalTemplateItems.templateId],
		references: [journalTemplates.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [journalTemplateItems.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const inventoryAdjustmentAttachmentsRelations = relations(inventoryAdjustmentAttachments, ({one}) => ({
	inventoryAdjustment: one(inventoryAdjustments, {
		fields: [inventoryAdjustmentAttachments.adjustmentId],
		references: [inventoryAdjustments.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryAdjustmentAttachments.entityId],
		references: [organisationBranchMaster.id]
	}),
	user: one(users, {
		fields: [inventoryAdjustmentAttachments.uploadedBy],
		references: [users.id]
	}),
}));

export const manualJournalItemsRelations = relations(manualJournalItems, ({one, many}) => ({
	account: one(accounts, {
		fields: [manualJournalItems.accountId],
		references: [accounts.id]
	}),
	manualJournal: one(manualJournals, {
		fields: [manualJournalItems.manualJournalId],
		references: [manualJournals.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [manualJournalItems.entityId],
		references: [organisationBranchMaster.id]
	}),
	manualJournalTagMappings: many(manualJournalTagMappings),
}));

export const inventoryPackagesRelations = relations(inventoryPackages, ({one, many}) => ({
	customer: one(customers, {
		fields: [inventoryPackages.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryPackages.entityId],
		references: [organisationBranchMaster.id]
	}),
	inventoryPackageItems: many(inventoryPackageItems),
	invoicePackages: many(invoicePackages),
	inventoryShipmentPackages: many(inventoryShipmentPackages),
	inventoryPackageSalesOrders: many(inventoryPackageSalesOrders),
}));

export const transferOrderMasterRelations = relations(transferOrderMaster, ({one, many}) => ({
	warehouse_destinationWarehouseId: one(warehouses, {
		fields: [transferOrderMaster.destinationWarehouseId],
		references: [warehouses.id],
		relationName: "transferOrderMaster_destinationWarehouseId_warehouses_id"
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [transferOrderMaster.entityId],
		references: [organisationBranchMaster.id]
	}),
	warehouse_sourceWarehouseId: one(warehouses, {
		fields: [transferOrderMaster.sourceWarehouseId],
		references: [warehouses.id],
		relationName: "transferOrderMaster_sourceWarehouseId_warehouses_id"
	}),
	transferOrderItems: many(transferOrderItems),
	transferOrderLogs: many(transferOrderLogs),
}));

export const branchesRelations = relations(branches, ({one, many}) => ({
	customers: many(customers),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [branches.id],
		references: [organisationBranchMaster.refId]
	}),
	assembliesConstituency_assemblyId: one(assembliesConstituencies, {
		fields: [branches.assemblyId],
		references: [assembliesConstituencies.id],
		relationName: "branches_assemblyId_assembliesConstituencies_id"
	}),
	businessType: one(businessTypes, {
		fields: [branches.branchType],
		references: [businessTypes.code]
	}),
	transactionSery: one(transactionSeries, {
		fields: [branches.defaultTransactionSeriesId],
		references: [transactionSeries.id]
	}),
	lsgdDistrict: one(lsgdDistricts, {
		fields: [branches.districtId],
		references: [lsgdDistricts.id]
	}),
	gstTreatment: one(gstTreatments, {
		fields: [branches.gstTreatment],
		references: [gstTreatments.code]
	}),
	account: one(accounts, {
		fields: [branches.gstinImportExportAccountId],
		references: [accounts.id]
	}),
	gstinRegistrationType: one(gstinRegistrationTypes, {
		fields: [branches.gstinRegistrationType],
		references: [gstinRegistrationTypes.code]
	}),
	lsgdLocalBody: one(lsgdLocalBodies, {
		fields: [branches.localBodyId],
		references: [lsgdLocalBodies.id]
	}),
	organization: one(organization, {
		fields: [branches.orgId],
		references: [organization.id]
	}),
	branch: one(branches, {
		fields: [branches.parentBranchId],
		references: [branches.id],
		relationName: "branches_parentBranchId_branches_id"
	}),
	branches: many(branches, {
		relationName: "branches_parentBranchId_branches_id"
	}),
	assembliesConstituency_paymentStubAssemblyId: one(assembliesConstituencies, {
		fields: [branches.paymentStubAssemblyId],
		references: [assembliesConstituencies.id],
		relationName: "branches_paymentStubAssemblyId_assembliesConstituencies_id"
	}),
	lsgdWard: one(lsgdWards, {
		fields: [branches.wardId],
		references: [lsgdWards.id]
	}),
	warehouses: many(warehouses),
}));

export const currenciesRelations = relations(currencies, ({many}) => ({
	customers: many(customers),
}));

export const productVendorMappingsRelations = relations(productVendorMappings, ({one}) => ({
	product: one(products, {
		fields: [productVendorMappings.itemId],
		references: [products.id]
	}),
}));

export const customerContactPersonsRelations = relations(customerContactPersons, ({one}) => ({
	customer: one(customers, {
		fields: [customerContactPersons.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [customerContactPersons.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const creditNotesRelations = relations(creditNotes, ({one, many}) => ({
	customer: one(customers, {
		fields: [creditNotes.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [creditNotes.entityId],
		references: [organisationBranchMaster.id]
	}),
	priceList: one(priceLists, {
		fields: [creditNotes.priceListId],
		references: [priceLists.id]
	}),
	warehouse: one(warehouses, {
		fields: [creditNotes.warehouseId],
		references: [warehouses.id]
	}),
	creditNoteItems: many(creditNoteItems),
}));

export const assembliesConstituenciesRelations = relations(assembliesConstituencies, ({one, many}) => ({
	lsgdDistrict: one(lsgdDistricts, {
		fields: [assembliesConstituencies.districtId],
		references: [lsgdDistricts.id]
	}),
	branches_assemblyId: many(branches, {
		relationName: "branches_assemblyId_assembliesConstituencies_id"
	}),
	branches_paymentStubAssemblyId: many(branches, {
		relationName: "branches_paymentStubAssemblyId_assembliesConstituencies_id"
	}),
	organizations_assemblyId: many(organization, {
		relationName: "organization_assemblyId_assembliesConstituencies_id"
	}),
	organizations_paymentStubAssemblyId: many(organization, {
		relationName: "organization_paymentStubAssemblyId_assembliesConstituencies_id"
	}),
	warehouses: many(warehouses),
}));

export const brandingRelations = relations(branding, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [branding.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const zoneLevelsRelations = relations(zoneLevels, ({one}) => ({
	zoneMaster: one(zoneMaster, {
		fields: [zoneLevels.zoneId],
		references: [zoneMaster.id]
	}),
}));

export const zoneMasterRelations = relations(zoneMaster, ({many}) => ({
	zoneLevels: many(zoneLevels),
	binMasters: many(binMaster),
}));

export const transferOrderItemsRelations = relations(transferOrderItems, ({one, many}) => ({
	product: one(products, {
		fields: [transferOrderItems.productId],
		references: [products.id]
	}),
	transferOrderMaster: one(transferOrderMaster, {
		fields: [transferOrderItems.transferOrderId],
		references: [transferOrderMaster.id]
	}),
	transferOrderSourceBatches: many(transferOrderSourceBatches),
	transferOrderDestinationBatches: many(transferOrderDestinationBatches),
}));

export const inventoryPackageItemsRelations = relations(inventoryPackageItems, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryPackageItems.entityId],
		references: [organisationBranchMaster.id]
	}),
	inventoryPackage: one(inventoryPackages, {
		fields: [inventoryPackageItems.packageId],
		references: [inventoryPackages.id]
	}),
	picklistMaster: one(picklistMaster, {
		fields: [inventoryPackageItems.picklistId],
		references: [picklistMaster.id]
	}),
	product: one(products, {
		fields: [inventoryPackageItems.productId],
		references: [products.id]
	}),
}));

export const picklistMasterRelations = relations(picklistMaster, ({many}) => ({
	inventoryPackageItems: many(inventoryPackageItems),
}));

export const transactionalSequencesRelations = relations(transactionalSequences, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [transactionalSequences.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const rolesRelations = relations(roles, ({one, many}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [roles.entityId],
		references: [organisationBranchMaster.id]
	}),
	branchUserAccesses: many(branchUserAccess),
}));

export const userBranchAccessRelations = relations(userBranchAccess, ({one}) => ({
	organization: one(organization, {
		fields: [userBranchAccess.orgId],
		references: [organization.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [userBranchAccess.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const organizationRelations = relations(organization, ({one, many}) => ({
	userBranchAccesses: many(userBranchAccess),
	branches: many(branches),
	assembliesConstituency_assemblyId: one(assembliesConstituencies, {
		fields: [organization.assemblyId],
		references: [assembliesConstituencies.id],
		relationName: "organization_assemblyId_assembliesConstituencies_id"
	}),
	lsgdDistrict_districtId: one(lsgdDistricts, {
		fields: [organization.districtId],
		references: [lsgdDistricts.id],
		relationName: "organization_districtId_lsgdDistricts_id"
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [organization.id],
		references: [organisationBranchMaster.refId]
	}),
	lsgdLocalBody_localBodyId: one(lsgdLocalBodies, {
		fields: [organization.localBodyId],
		references: [lsgdLocalBodies.id],
		relationName: "organization_localBodyId_lsgdLocalBodies_id"
	}),
	assembliesConstituency_paymentStubAssemblyId: one(assembliesConstituencies, {
		fields: [organization.paymentStubAssemblyId],
		references: [assembliesConstituencies.id],
		relationName: "organization_paymentStubAssemblyId_assembliesConstituencies_id"
	}),
	lsgdDistrict_paymentStubDistrictId: one(lsgdDistricts, {
		fields: [organization.paymentStubDistrictId],
		references: [lsgdDistricts.id],
		relationName: "organization_paymentStubDistrictId_lsgdDistricts_id"
	}),
	lsgdLocalBody_paymentStubLocalBodyId: one(lsgdLocalBodies, {
		fields: [organization.paymentStubLocalBodyId],
		references: [lsgdLocalBodies.id],
		relationName: "organization_paymentStubLocalBodyId_lsgdLocalBodies_id"
	}),
	lsgdWard_paymentStubWardId: one(lsgdWards, {
		fields: [organization.paymentStubWardId],
		references: [lsgdWards.id],
		relationName: "organization_paymentStubWardId_lsgdWards_id"
	}),
	state: one(states, {
		fields: [organization.stateId],
		references: [states.id]
	}),
	lsgdWard_wardId: one(lsgdWards, {
		fields: [organization.wardId],
		references: [lsgdWards.id],
		relationName: "organization_wardId_lsgdWards_id"
	}),
}));

export const inventoryAdjustmentReasonsRelations = relations(inventoryAdjustmentReasons, ({one, many}) => ({
	inventoryAdjustments: many(inventoryAdjustments),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryAdjustmentReasons.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const inventoryAdjustmentItemBatchesRelations = relations(inventoryAdjustmentItemBatches, ({one}) => ({
	inventoryAdjustment: one(inventoryAdjustments, {
		fields: [inventoryAdjustmentItemBatches.adjustmentId],
		references: [inventoryAdjustments.id]
	}),
	inventoryAdjustmentItem: one(inventoryAdjustmentItems, {
		fields: [inventoryAdjustmentItemBatches.adjustmentItemId],
		references: [inventoryAdjustmentItems.id]
	}),
	batchMaster: one(batchMaster, {
		fields: [inventoryAdjustmentItemBatches.batchId],
		references: [batchMaster.id]
	}),
	batchStockLayer: one(batchStockLayers, {
		fields: [inventoryAdjustmentItemBatches.batchStockLayerId],
		references: [batchStockLayers.id]
	}),
	binMaster: one(binMaster, {
		fields: [inventoryAdjustmentItemBatches.binId],
		references: [binMaster.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryAdjustmentItemBatches.entityId],
		references: [organisationBranchMaster.id]
	}),
	product: one(products, {
		fields: [inventoryAdjustmentItemBatches.productId],
		references: [products.id]
	}),
	warehouse: one(warehouses, {
		fields: [inventoryAdjustmentItemBatches.warehouseId],
		references: [warehouses.id]
	}),
}));

export const creditNoteItemsRelations = relations(creditNoteItems, ({one, many}) => ({
	account: one(accounts, {
		fields: [creditNoteItems.accountId],
		references: [accounts.id]
	}),
	creditNote: one(creditNotes, {
		fields: [creditNoteItems.creditNoteId],
		references: [creditNotes.id]
	}),
	product: one(products, {
		fields: [creditNoteItems.productId],
		references: [products.id]
	}),
	creditNoteItemBatches: many(creditNoteItemBatches),
}));

export const businessTypesRelations = relations(businessTypes, ({many}) => ({
	branches: many(branches),
}));

export const gstTreatmentsRelations = relations(gstTreatments, ({many}) => ({
	branches: many(branches),
}));

export const gstinRegistrationTypesRelations = relations(gstinRegistrationTypes, ({many}) => ({
	branches: many(branches),
}));

export const branchUserAccessRelations = relations(branchUserAccess, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [branchUserAccess.entityId],
		references: [organisationBranchMaster.id]
	}),
	role: one(roles, {
		fields: [branchUserAccess.roleId],
		references: [roles.id]
	}),
	user: one(users, {
		fields: [branchUserAccess.userId],
		references: [users.id]
	}),
}));

export const reportingTagsRelations = relations(reportingTags, ({one, many}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [reportingTags.entityId],
		references: [organisationBranchMaster.id]
	}),
	manualJournalTagMappings: many(manualJournalTagMappings),
}));

export const creditNoteItemBatchesRelations = relations(creditNoteItemBatches, ({one}) => ({
	batchMaster: one(batchMaster, {
		fields: [creditNoteItemBatches.batchId],
		references: [batchMaster.id]
	}),
	binMaster: one(binMaster, {
		fields: [creditNoteItemBatches.binId],
		references: [binMaster.id]
	}),
	creditNoteItem: one(creditNoteItems, {
		fields: [creditNoteItemBatches.creditNoteItemId],
		references: [creditNoteItems.id]
	}),
	batchStockLayer: one(batchStockLayers, {
		fields: [creditNoteItemBatches.layerId],
		references: [batchStockLayers.id]
	}),
	warehouse: one(warehouses, {
		fields: [creditNoteItemBatches.warehouseId],
		references: [warehouses.id]
	}),
}));

export const salesReturnReceiveItemsRelations = relations(salesReturnReceiveItems, ({one, many}) => ({
	salesReturnReceive: one(salesReturnReceives, {
		fields: [salesReturnReceiveItems.salesReturnReceiveId],
		references: [salesReturnReceives.id]
	}),
	salesReturnItem: one(salesReturnItems, {
		fields: [salesReturnReceiveItems.salesReturnItemId],
		references: [salesReturnItems.id]
	}),
	salesReturnReceiveBatches: many(salesReturnReceiveBatches),
}));

export const salesReturnItemsRelations = relations(salesReturnItems, ({one, many}) => ({
	salesReturnReceiveItems: many(salesReturnReceiveItems),
	salesReturn: one(salesReturns, {
		fields: [salesReturnItems.salesReturnId],
		references: [salesReturns.id]
	}),
}));

export const compositeItemBranchInventorySettingsRelations = relations(compositeItemBranchInventorySettings, ({one}) => ({
	compositeItem: one(compositeItems, {
		fields: [compositeItemBranchInventorySettings.compositeItemId],
		references: [compositeItems.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [compositeItemBranchInventorySettings.entityId],
		references: [organisationBranchMaster.id]
	}),
	reorderTerm: one(reorderTerms, {
		fields: [compositeItemBranchInventorySettings.reorderTermId],
		references: [reorderTerms.id]
	}),
}));

export const productBranchInventorySettingsRelations = relations(productBranchInventorySettings, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [productBranchInventorySettings.entityId],
		references: [organisationBranchMaster.id]
	}),
	product: one(products, {
		fields: [productBranchInventorySettings.productId],
		references: [products.id]
	}),
	reorderTerm: one(reorderTerms, {
		fields: [productBranchInventorySettings.reorderTermId],
		references: [reorderTerms.id]
	}),
}));

export const transferOrderSourceBatchesRelations = relations(transferOrderSourceBatches, ({one}) => ({
	batchMaster: one(batchMaster, {
		fields: [transferOrderSourceBatches.batchId],
		references: [batchMaster.id]
	}),
	binMaster: one(binMaster, {
		fields: [transferOrderSourceBatches.binId],
		references: [binMaster.id]
	}),
	transferOrderItem: one(transferOrderItems, {
		fields: [transferOrderSourceBatches.transferItemId],
		references: [transferOrderItems.id]
	}),
	batchStockLayer: one(batchStockLayers, {
		fields: [transferOrderSourceBatches.layerId],
		references: [batchStockLayers.id]
	}),
	warehouse: one(warehouses, {
		fields: [transferOrderSourceBatches.warehouseId],
		references: [warehouses.id]
	}),
}));

export const transferOrderDestinationBatchesRelations = relations(transferOrderDestinationBatches, ({one}) => ({
	binMaster: one(binMaster, {
		fields: [transferOrderDestinationBatches.destinationBinId],
		references: [binMaster.id]
	}),
	transferOrderItem: one(transferOrderItems, {
		fields: [transferOrderDestinationBatches.transferItemId],
		references: [transferOrderItems.id]
	}),
	warehouse: one(warehouses, {
		fields: [transferOrderDestinationBatches.destinationWarehouseId],
		references: [warehouses.id]
	}),
}));

export const transferOrderLogsRelations = relations(transferOrderLogs, ({one}) => ({
	transferOrderMaster: one(transferOrderMaster, {
		fields: [transferOrderLogs.transferOrderId],
		references: [transferOrderMaster.id]
	}),
}));

export const invoicePackagesRelations = relations(invoicePackages, ({one}) => ({
	invoiceMaster: one(invoiceMaster, {
		fields: [invoicePackages.invoiceId],
		references: [invoiceMaster.id]
	}),
	inventoryPackage: one(inventoryPackages, {
		fields: [invoicePackages.packageId],
		references: [inventoryPackages.id]
	}),
}));

export const salesReturnReceiveBatchesRelations = relations(salesReturnReceiveBatches, ({one}) => ({
	batchMaster: one(batchMaster, {
		fields: [salesReturnReceiveBatches.batchId],
		references: [batchMaster.id]
	}),
	binMaster: one(binMaster, {
		fields: [salesReturnReceiveBatches.binId],
		references: [binMaster.id]
	}),
	batchStockLayer: one(batchStockLayers, {
		fields: [salesReturnReceiveBatches.layerId],
		references: [batchStockLayers.id]
	}),
	salesReturnReceiveItem: one(salesReturnReceiveItems, {
		fields: [salesReturnReceiveBatches.salesReturnReceiveItemId],
		references: [salesReturnReceiveItems.id]
	}),
	warehouse: one(warehouses, {
		fields: [salesReturnReceiveBatches.warehouseId],
		references: [warehouses.id]
	}),
}));

export const inventoryMoveOrderItemsRelations = relations(inventoryMoveOrderItems, ({one, many}) => ({
	inventoryMoveOrder: one(inventoryMoveOrders, {
		fields: [inventoryMoveOrderItems.moveOrderId],
		references: [inventoryMoveOrders.id]
	}),
	inventoryMoveOrderSourceBatches: many(inventoryMoveOrderSourceBatches),
}));

export const inventoryMoveOrdersRelations = relations(inventoryMoveOrders, ({many}) => ({
	inventoryMoveOrderItems: many(inventoryMoveOrderItems),
	moveOrderAttachments: many(moveOrderAttachments),
}));

export const inventoryMoveOrderSourceBatchesRelations = relations(inventoryMoveOrderSourceBatches, ({one, many}) => ({
	inventoryMoveOrderItem: one(inventoryMoveOrderItems, {
		fields: [inventoryMoveOrderSourceBatches.moveOrderItemId],
		references: [inventoryMoveOrderItems.id]
	}),
	inventoryMoveOrderDestinationBins: many(inventoryMoveOrderDestinationBins),
}));

export const inventoryMoveOrderDestinationBinsRelations = relations(inventoryMoveOrderDestinationBins, ({one}) => ({
	inventoryMoveOrderSourceBatch: one(inventoryMoveOrderSourceBatches, {
		fields: [inventoryMoveOrderDestinationBins.sourceBatchRowId],
		references: [inventoryMoveOrderSourceBatches.id]
	}),
}));

export const moveOrderAttachmentsRelations = relations(moveOrderAttachments, ({one}) => ({
	inventoryMoveOrder: one(inventoryMoveOrders, {
		fields: [moveOrderAttachments.moveOrderId],
		references: [inventoryMoveOrders.id]
	}),
}));

export const paymentReceivedAllocationsRelations = relations(paymentReceivedAllocations, ({one}) => ({
	invoiceMaster: one(invoiceMaster, {
		fields: [paymentReceivedAllocations.salesInvoiceId],
		references: [invoiceMaster.id]
	}),
	paymentsReceived: one(paymentsReceived, {
		fields: [paymentReceivedAllocations.paymentReceivedId],
		references: [paymentsReceived.id]
	}),
}));

export const paymentsReceivedRelations = relations(paymentsReceived, ({one, many}) => ({
	paymentReceivedAllocations: many(paymentReceivedAllocations),
	customer: one(customers, {
		fields: [paymentsReceived.customerId],
		references: [customers.id]
	}),
}));

export const salesOrderItemsRelations = relations(salesOrderItems, ({one}) => ({
	account: one(accounts, {
		fields: [salesOrderItems.accounts],
		references: [accounts.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [salesOrderItems.entityId],
		references: [organisationBranchMaster.id]
	}),
	product: one(products, {
		fields: [salesOrderItems.productId],
		references: [products.id]
	}),
	salesOrder: one(salesOrders, {
		fields: [salesOrderItems.salesOrderId],
		references: [salesOrders.id]
	}),
	taxRate: one(taxRates, {
		fields: [salesOrderItems.taxId],
		references: [taxRates.id]
	}),
	warehouse: one(warehouses, {
		fields: [salesOrderItems.warehouseId],
		references: [warehouses.id]
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

export const branchPriceListAssignmentsRelations = relations(branchPriceListAssignments, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [branchPriceListAssignments.branchEntityId],
		references: [organisationBranchMaster.id]
	}),
	priceList: one(priceLists, {
		fields: [branchPriceListAssignments.priceListId],
		references: [priceLists.id]
	}),
}));

export const priceListVolumeRangesRelations = relations(priceListVolumeRanges, ({one}) => ({
	priceListItem: one(priceListItems, {
		fields: [priceListVolumeRanges.priceListItemId],
		references: [priceListItems.id]
	}),
}));

export const productEntitySettingsRelations = relations(productEntitySettings, ({one}) => ({
	vendor: one(vendors, {
		fields: [productEntitySettings.preferredVendorId],
		references: [vendors.id]
	}),
	product: one(products, {
		fields: [productEntitySettings.productId],
		references: [products.id]
	}),
	reorderTerm: one(reorderTerms, {
		fields: [productEntitySettings.reorderTermId],
		references: [reorderTerms.id]
	}),
}));

export const productBinMappingsRelations = relations(productBinMappings, ({one}) => ({
	product: one(products, {
		fields: [productBinMappings.productId],
		references: [products.id]
	}),
}));

export const manualJournalTagMappingsRelations = relations(manualJournalTagMappings, ({one}) => ({
	manualJournalItem: one(manualJournalItems, {
		fields: [manualJournalTagMappings.manualJournalItemId],
		references: [manualJournalItems.id]
	}),
	reportingTag: one(reportingTags, {
		fields: [manualJournalTagMappings.reportingTagId],
		references: [reportingTags.id]
	}),
}));

export const inventoryShipmentSalesOrdersRelations = relations(inventoryShipmentSalesOrders, ({one}) => ({
	salesOrder: one(salesOrders, {
		fields: [inventoryShipmentSalesOrders.salesOrderId],
		references: [salesOrders.id]
	}),
	inventoryShipment: one(inventoryShipments, {
		fields: [inventoryShipmentSalesOrders.shipmentId],
		references: [inventoryShipments.id]
	}),
}));

export const inventoryShipmentPackagesRelations = relations(inventoryShipmentPackages, ({one}) => ({
	inventoryPackage: one(inventoryPackages, {
		fields: [inventoryShipmentPackages.packageId],
		references: [inventoryPackages.id]
	}),
	inventoryShipment: one(inventoryShipments, {
		fields: [inventoryShipmentPackages.shipmentId],
		references: [inventoryShipments.id]
	}),
}));

export const inventoryPackageSalesOrdersRelations = relations(inventoryPackageSalesOrders, ({one}) => ({
	inventoryPackage: one(inventoryPackages, {
		fields: [inventoryPackageSalesOrders.packageId],
		references: [inventoryPackages.id]
	}),
}));