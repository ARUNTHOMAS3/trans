import { relations } from "drizzle-orm/relations";
import { inventoryMoveOrderItems, inventoryMoveOrderSourceBatches, organisationBranchMaster, journalEntries, fiscalYears, purchaseReceives, purchaseOrders, warehouses, taxGroups, taxGroupRates, taxRates, inventoryAdjustmentReasons, inventoryAdjustments, accounts, users, products, transactionLocks, invoiceMaster, countries, states, contents, productContents, drugSchedules, drugStrengths, customers, salesPaymentLinks, salesOrderItems, salesOrders, batchMaster, purchaseOrderAttachments, paymentTerms, priceLists, tdsRates, productBranchInventorySettings, reorderTerms, categories, bills, billLandedCosts, binMaster, purchaseReceiveItems, accountTransactions, inventoryMoveOrderDestinationBins, journalNumberSettings, journalTemplates, invoiceSalesOrders, manualJournals, recurringJournals, salesOrderAttachments, picklistMaster, invoiceShipments, inventoryShipments, manualJournalAttachments, inventoryAdjustmentValueItems, branchTransactionSeries, transactionSeries, inventoryPackageItems, inventoryPackages, transferOrderItems, transferOrderMaster, branchUsers, lsgdLocalBodies, lsgdWards, picklistBatchAllocation, picklistItems, vendors, vendorContactPersons, vendorAddresses, carrier, creditNoteItems, creditNotes, lsgdDistricts, auditLogsArchive, salesPayments, invoiceAttachments, salesReturns, salesReturnReceives, billItems, vendorBankAccounts, auditLogs, tdsSections, uqc, units, timezones, tdsGroups, tdsGroupItems, recurringJournalItems, journalTemplateItems, productEcommerce, brands, compositeItems, manufacturers, branches, currencies, gstTreatments, salesReturnReceiveBatches, batchStockLayers, salesReturnReceiveItems, vendorCreditItems, vendorCreditItemBatches, expenseItems, expenses, customerContactPersons, assembliesConstituencies, branding, zoneMaster, zoneLevels, manualJournalItems, inventoryAdjustmentAccountEntries, transactionalSequences, roles, organization, userBranchAccess, paymentsReceived, businessTypes, gstinRegistrationTypes, branchUserAccess, paymentReceivedAllocations, reportingTags, paymentReceivedAttachments, expenseAttachments, recurringInvoices, compositeItemParts, transferOrderLogs, purchaseReceiveAttachments, invoicePackages, expenseMileage, salesReps, inventoryMoveOrders, moveOrderAttachments, purchaseOrderItems, recurringInvoiceItems, retainerInvoices, recurringExpenses, stockCountItems, vendorCredits, purchaseReturns, generalPreferences, recurringExpenseReceipts, branchPriceListAssignments, purchaseReceiveItemBatches, currencyExchangeRates, recurringInvoiceRuns, demandPool, purchaseRequests, unitGroups, itemRegistrationRequests, purchaseRequestItems, billAttachments, unitGroupConversions, purchaseRequestVendorChecks, tcsHigherRateReasons, tcsRates, tcsNatures, inventoryAdjustmentItems, inventoryAdjustmentItemBatches, procurementSubstitutions, reportingTagOptions, reportingTagModuleMappings, purchaseOrderRequestAllocations, demandAllocations, recurringExpenseRuns, recurringInvoiceAttachments, retainerInvoiceItems, paymentMadePaymentMode, transferOrderDestinationBatches, priceListItems, priceListVolumeRanges, invoiceItemBatches, invoiceItems, creditNoteItemBatches, billItemBatches, paymentMadeMaster, retainerInvoiceAttachments, salesReturnItems, retainerInvoiceApplications, buyingRules, productTypes, racks, storageConditions, productPackSizes, paymentMadeTax, inventoryStockCount, deliveryChallans, deliveryChallanAttachments, deliveryChallanDocumentLinks, productEntitySettings, productBinMappings, reminderRules, paymentMadeBillAllocations, deliveryChallanItems, inventoryRecurringStockCount, deliveryChallanItemBatches, purchaseRequestApproval, purchaseReturnItems, vendorAdvanceAllocations, printTemplates, inventoryAdjustmentAttachments, transferOrderSourceBatches, purchaseReturnItemBatches, customerAddresses, paymentMadeAttachments, emailNotificationTemplates, customFields, approvalRules, productVendorMappings, defaultPaymentTerms, recordLocking, vendorCreditsAttachments, manualJournalTagMappings, inventoryShipmentSalesOrders, inventoryShipmentPackages, inventoryPackageSalesOrders } from "./schema";

export const inventoryMoveOrderSourceBatchesRelations = relations(inventoryMoveOrderSourceBatches, ({one, many}) => ({
	inventoryMoveOrderItem: one(inventoryMoveOrderItems, {
		fields: [inventoryMoveOrderSourceBatches.moveOrderItemId],
		references: [inventoryMoveOrderItems.id]
	}),
	inventoryMoveOrderDestinationBins: many(inventoryMoveOrderDestinationBins),
}));

export const inventoryMoveOrderItemsRelations = relations(inventoryMoveOrderItems, ({one, many}) => ({
	inventoryMoveOrderSourceBatches: many(inventoryMoveOrderSourceBatches),
	inventoryMoveOrder: one(inventoryMoveOrders, {
		fields: [inventoryMoveOrderItems.moveOrderId],
		references: [inventoryMoveOrders.id]
	}),
}));

export const journalEntriesRelations = relations(journalEntries, ({one, many}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [journalEntries.entityId],
		references: [organisationBranchMaster.id]
	}),
	fiscalYear: one(fiscalYears, {
		fields: [journalEntries.fiscalYearId],
		references: [fiscalYears.id]
	}),
	journalEntry: one(journalEntries, {
		fields: [journalEntries.reversalOfId],
		references: [journalEntries.id],
		relationName: "journalEntries_reversalOfId_journalEntries_id"
	}),
	journalEntries: many(journalEntries, {
		relationName: "journalEntries_reversalOfId_journalEntries_id"
	}),
	accountTransactions: many(accountTransactions),
	manualJournals: many(manualJournals),
}));

export const organisationBranchMasterRelations = relations(organisationBranchMaster, ({many}) => ({
	journalEntries: many(journalEntries),
	purchaseReceives: many(purchaseReceives),
	inventoryAdjustments: many(inventoryAdjustments),
	transactionLocks: many(transactionLocks),
	invoiceMasters: many(invoiceMaster),
	salesPaymentLinks: many(salesPaymentLinks),
	salesOrderItems: many(salesOrderItems),
	batchMasters: many(batchMaster),
	accounts: many(accounts),
	salesOrders: many(salesOrders),
	productBranchInventorySettings: many(productBranchInventorySettings),
	purchaseReceiveItems: many(purchaseReceiveItems),
	accountTransactions: many(accountTransactions),
	journalNumberSettings: many(journalNumberSettings),
	journalTemplates: many(journalTemplates),
	manualJournals: many(manualJournals),
	salesOrderAttachments: many(salesOrderAttachments),
	manualJournalAttachments: many(manualJournalAttachments),
	inventoryAdjustmentValueItems: many(inventoryAdjustmentValueItems),
	branchTransactionSeries: many(branchTransactionSeries),
	inventoryPackageItems: many(inventoryPackageItems),
	branchUsers: many(branchUsers),
	recurringJournals: many(recurringJournals),
	reorderTerms: many(reorderTerms),
	purchaseOrders: many(purchaseOrders),
	auditLogsArchives: many(auditLogsArchive),
	salesPayments: many(salesPayments),
	auditLogs: many(auditLogs),
	fiscalYears: many(fiscalYears),
	journalTemplateItems: many(journalTemplateItems),
	inventoryPackages: many(inventoryPackages),
	transferOrderMasters: many(transferOrderMaster),
	customers: many(customers),
	customerContactPersons: many(customerContactPersons),
	creditNotes: many(creditNotes),
	brandings: many(branding),
	users: many(users),
	manualJournalItems: many(manualJournalItems),
	inventoryAdjustmentAccountEntries: many(inventoryAdjustmentAccountEntries),
	transactionalSequences: many(transactionalSequences),
	roles: many(roles),
	transactionSeries: many(transactionSeries),
	userBranchAccesses: many(userBranchAccess),
	paymentsReceiveds: many(paymentsReceived),
	inventoryAdjustmentReasons: many(inventoryAdjustmentReasons),
	branches: many(branches),
	branchUserAccesses: many(branchUserAccess),
	reportingTags: many(reportingTags),
	organizations: many(organization),
	recurringInvoices: many(recurringInvoices),
	warehouses: many(warehouses),
	inventoryShipments: many(inventoryShipments),
	salesReps: many(salesReps),
	purchaseOrderItems: many(purchaseOrderItems),
	retainerInvoices: many(retainerInvoices),
	recurringExpenses: many(recurringExpenses),
	priceLists_createdByEntityId: many(priceLists, {
		relationName: "priceLists_createdByEntityId_organisationBranchMaster_id"
	}),
	priceLists_entityId: many(priceLists, {
		relationName: "priceLists_entityId_organisationBranchMaster_id"
	}),
	generalPreferences: many(generalPreferences),
	branchPriceListAssignments: many(branchPriceListAssignments),
	purchaseReceiveItemBatches: many(purchaseReceiveItemBatches),
	bills: many(bills),
	currencyExchangeRates: many(currencyExchangeRates),
	demandPools: many(demandPool),
	unitGroups: many(unitGroups),
	itemRegistrationRequests: many(itemRegistrationRequests),
	purchaseRequests: many(purchaseRequests),
	vendorAddresses: many(vendorAddresses),
	inventoryAdjustmentItems: many(inventoryAdjustmentItems),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	procurementSubstitutions: many(procurementSubstitutions),
	paymentMadePaymentModes: many(paymentMadePaymentMode),
	vendors: many(vendors),
	paymentMadeMasters: many(paymentMadeMaster),
	inventoryStockCounts: many(inventoryStockCount),
	deliveryChallans: many(deliveryChallans),
	reminderRules: many(reminderRules),
	inventoryRecurringStockCounts: many(inventoryRecurringStockCount),
	deliveryChallanItemBatches: many(deliveryChallanItemBatches),
	purchaseRequestApprovals: many(purchaseRequestApproval),
	printTemplates: many(printTemplates),
	inventoryAdjustmentAttachments: many(inventoryAdjustmentAttachments),
	customerAddresses: many(customerAddresses),
	emailNotificationTemplates: many(emailNotificationTemplates),
	customFields: many(customFields),
	approvalRules: many(approvalRules),
	expenses: many(expenses),
	defaultPaymentTerms: many(defaultPaymentTerms),
	recordLockings: many(recordLocking),
}));

export const fiscalYearsRelations = relations(fiscalYears, ({one, many}) => ({
	journalEntries: many(journalEntries),
	manualJournals: many(manualJournals),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [fiscalYears.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const purchaseReceivesRelations = relations(purchaseReceives, ({one, many}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [purchaseReceives.entityId],
		references: [organisationBranchMaster.id]
	}),
	purchaseOrder: one(purchaseOrders, {
		fields: [purchaseReceives.purchaseOrderId],
		references: [purchaseOrders.id]
	}),
	warehouse: one(warehouses, {
		fields: [purchaseReceives.warehouseId],
		references: [warehouses.id]
	}),
	purchaseReceiveItems: many(purchaseReceiveItems),
	purchaseReceiveAttachments: many(purchaseReceiveAttachments),
}));

export const purchaseOrdersRelations = relations(purchaseOrders, ({one, many}) => ({
	purchaseReceives: many(purchaseReceives),
	purchaseOrderAttachments: many(purchaseOrderAttachments),
	vendorAddress_billingAddress: one(vendorAddresses, {
		fields: [purchaseOrders.billingAddress],
		references: [vendorAddresses.id],
		relationName: "purchaseOrders_billingAddress_vendorAddresses_id"
	}),
	account: one(accounts, {
		fields: [purchaseOrders.discountAccountId],
		references: [accounts.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [purchaseOrders.entityId],
		references: [organisationBranchMaster.id]
	}),
	vendorAddress_shippingAddress: one(vendorAddresses, {
		fields: [purchaseOrders.shippingAddress],
		references: [vendorAddresses.id],
		relationName: "purchaseOrders_shippingAddress_vendorAddresses_id"
	}),
	tdsRate: one(tdsRates, {
		fields: [purchaseOrders.tdsTcsId],
		references: [tdsRates.id]
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
	vendor: one(vendors, {
		fields: [purchaseOrders.vendorId],
		references: [vendors.id]
	}),
	warehouse_warehouseId: one(warehouses, {
		fields: [purchaseOrders.warehouseId],
		references: [warehouses.id],
		relationName: "purchaseOrders_warehouseId_warehouses_id"
	}),
	purchaseOrderItems: many(purchaseOrderItems),
}));

export const warehousesRelations = relations(warehouses, ({one, many}) => ({
	purchaseReceives: many(purchaseReceives),
	inventoryAdjustments: many(inventoryAdjustments),
	salesOrderItems: many(salesOrderItems),
	salesOrders: many(salesOrders),
	purchaseReceiveItems: many(purchaseReceiveItems),
	picklistMasters: many(picklistMaster),
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
	salesReturnReceiveBatches: many(salesReturnReceiveBatches),
	creditNotes: many(creditNotes),
	users: many(users),
	binMasters: many(binMaster),
	recurringInvoices: many(recurringInvoices),
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
	organization: one(organization, {
		fields: [warehouses.orgId],
		references: [organization.id]
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
	purchaseReceiveItemBatches: many(purchaseReceiveItemBatches),
	bills: many(bills),
	demandPools: many(demandPool),
	purchaseRequests: many(purchaseRequests),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	procurementSubstitutions: many(procurementSubstitutions),
	transferOrderDestinationBatches: many(transferOrderDestinationBatches),
	creditNoteItemBatches: many(creditNoteItemBatches),
	billItemBatches: many(billItemBatches),
	batchStockLayers: many(batchStockLayers),
	inventoryStockCounts_warehouse: many(inventoryStockCount, {
		relationName: "inventoryStockCount_warehouse_warehouses_id"
	}),
	inventoryStockCounts_warehouseId: many(inventoryStockCount, {
		relationName: "inventoryStockCount_warehouseId_warehouses_id"
	}),
	deliveryChallans: many(deliveryChallans),
	inventoryRecurringStockCounts: many(inventoryRecurringStockCount),
	deliveryChallanItemBatches: many(deliveryChallanItemBatches),
	transferOrderSourceBatches: many(transferOrderSourceBatches),
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
	billItems: many(billItems),
	products_interStateTaxId: many(products, {
		relationName: "products_interStateTaxId_taxGroups_id"
	}),
	products_intraStateTaxId: many(products, {
		relationName: "products_intraStateTaxId_taxGroups_id"
	}),
}));

export const taxRatesRelations = relations(taxRates, ({many}) => ({
	taxGroupRates: many(taxGroupRates),
	salesOrderItems: many(salesOrderItems),
	compositeItems_interStateTaxId: many(compositeItems, {
		relationName: "compositeItems_interStateTaxId_taxRates_id"
	}),
	compositeItems_intraStateTaxId: many(compositeItems, {
		relationName: "compositeItems_intraStateTaxId_taxRates_id"
	}),
	expenseItems: many(expenseItems),
	recurringInvoiceItems: many(recurringInvoiceItems),
	deliveryChallanItems: many(deliveryChallanItems),
	expenses: many(expenses),
}));

export const inventoryAdjustmentsRelations = relations(inventoryAdjustments, ({one, many}) => ({
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
	inventoryAdjustmentValueItems: many(inventoryAdjustmentValueItems),
	inventoryAdjustmentAccountEntries: many(inventoryAdjustmentAccountEntries),
	inventoryAdjustmentItems: many(inventoryAdjustmentItems),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	inventoryAdjustmentAttachments: many(inventoryAdjustmentAttachments),
}));

export const inventoryAdjustmentReasonsRelations = relations(inventoryAdjustmentReasons, ({one, many}) => ({
	inventoryAdjustments: many(inventoryAdjustments),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryAdjustmentReasons.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const accountsRelations = relations(accounts, ({one, many}) => ({
	inventoryAdjustments: many(inventoryAdjustments),
	salesOrderItems: many(salesOrderItems),
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
	accountTransactions: many(accountTransactions),
	purchaseOrders: many(purchaseOrders),
	creditNoteItems: many(creditNoteItems),
	billItems_accountId: many(billItems, {
		relationName: "billItems_accountId_accounts_id"
	}),
	billItems_discountAccountsId: many(billItems, {
		relationName: "billItems_discountAccountsId_accounts_id"
	}),
	tdsRates_payableAccountId: many(tdsRates, {
		relationName: "tdsRates_payableAccountId_accounts_id"
	}),
	tdsRates_receivableAccountId: many(tdsRates, {
		relationName: "tdsRates_receivableAccountId_accounts_id"
	}),
	recurringJournalItems: many(recurringJournalItems),
	journalTemplateItems: many(journalTemplateItems),
	compositeItems_inventoryAccountId: many(compositeItems, {
		relationName: "compositeItems_inventoryAccountId_accounts_id"
	}),
	compositeItems_purchaseAccountId: many(compositeItems, {
		relationName: "compositeItems_purchaseAccountId_accounts_id"
	}),
	compositeItems_salesAccountId: many(compositeItems, {
		relationName: "compositeItems_salesAccountId_accounts_id"
	}),
	expenseItems: many(expenseItems),
	manualJournalItems: many(manualJournalItems),
	inventoryAdjustmentAccountEntries: many(inventoryAdjustmentAccountEntries),
	paymentsReceiveds: many(paymentsReceived),
	branches: many(branches),
	purchaseOrderItems: many(purchaseOrderItems),
	recurringInvoiceItems: many(recurringInvoiceItems),
	recurringExpenses_expenseAccountId: many(recurringExpenses, {
		relationName: "recurringExpenses_expenseAccountId_accounts_id"
	}),
	recurringExpenses_paidThroughAccountId: many(recurringExpenses, {
		relationName: "recurringExpenses_paidThroughAccountId_accounts_id"
	}),
	bills: many(bills),
	tcsRates_payableAccountId: many(tcsRates, {
		relationName: "tcsRates_payableAccountId_accounts_id"
	}),
	tcsRates_receivableAccountId: many(tcsRates, {
		relationName: "tcsRates_receivableAccountId_accounts_id"
	}),
	paymentMadeMasters_depositToAccountId: many(paymentMadeMaster, {
		relationName: "paymentMadeMaster_depositToAccountId_accounts_id"
	}),
	paymentMadeMasters_paidThroughAccountId: many(paymentMadeMaster, {
		relationName: "paymentMadeMaster_paidThroughAccountId_accounts_id"
	}),
	invoiceItems: many(invoiceItems),
	products_inventoryAccountId: many(products, {
		relationName: "products_inventoryAccountId_accounts_id"
	}),
	products_purchaseAccountId: many(products, {
		relationName: "products_purchaseAccountId_accounts_id"
	}),
	products_salesAccountId: many(products, {
		relationName: "products_salesAccountId_accounts_id"
	}),
	deliveryChallanItems: many(deliveryChallanItems),
	expenses_expenseAccountId: many(expenses, {
		relationName: "expenses_expenseAccountId_accounts_id"
	}),
	expenses_paidThroughAccountId: many(expenses, {
		relationName: "expenses_paidThroughAccountId_accounts_id"
	}),
}));

export const usersRelations = relations(users, ({one, many}) => ({
	inventoryAdjustments_adjustedBy: many(inventoryAdjustments, {
		relationName: "inventoryAdjustments_adjustedBy_users_id"
	}),
	inventoryAdjustments_approvedBy: many(inventoryAdjustments, {
		relationName: "inventoryAdjustments_approvedBy_users_id"
	}),
	branchUsers: many(branchUsers),
	warehouse: one(warehouses, {
		fields: [users.defaultWarehouseId],
		references: [warehouses.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [users.entityId],
		references: [organisationBranchMaster.id]
	}),
	branchUserAccesses: many(branchUserAccess),
	expenseAttachments: many(expenseAttachments),
	recurringInvoices_createdBy: many(recurringInvoices, {
		relationName: "recurringInvoices_createdBy_users_id"
	}),
	recurringInvoices_salespersonId: many(recurringInvoices, {
		relationName: "recurringInvoices_salespersonId_users_id"
	}),
	recurringInvoices_updatedBy: many(recurringInvoices, {
		relationName: "recurringInvoices_updatedBy_users_id"
	}),
	expenseMileages: many(expenseMileage),
	demandPools_createdBy: many(demandPool, {
		relationName: "demandPool_createdBy_users_id"
	}),
	demandPools_updatedBy: many(demandPool, {
		relationName: "demandPool_updatedBy_users_id"
	}),
	itemRegistrationRequests_assignedTo: many(itemRegistrationRequests, {
		relationName: "itemRegistrationRequests_assignedTo_users_id"
	}),
	itemRegistrationRequests_completedBy: many(itemRegistrationRequests, {
		relationName: "itemRegistrationRequests_completedBy_users_id"
	}),
	itemRegistrationRequests_requestedBy: many(itemRegistrationRequests, {
		relationName: "itemRegistrationRequests_requestedBy_users_id"
	}),
	purchaseRequests_approvedBy: many(purchaseRequests, {
		relationName: "purchaseRequests_approvedBy_users_id"
	}),
	purchaseRequests_assigneeId: many(purchaseRequests, {
		relationName: "purchaseRequests_assigneeId_users_id"
	}),
	purchaseRequests_createdBy: many(purchaseRequests, {
		relationName: "purchaseRequests_createdBy_users_id"
	}),
	purchaseRequestVendorChecks: many(purchaseRequestVendorChecks),
	procurementSubstitutions_approvedBy: many(procurementSubstitutions, {
		relationName: "procurementSubstitutions_approvedBy_users_id"
	}),
	procurementSubstitutions_createdBy: many(procurementSubstitutions, {
		relationName: "procurementSubstitutions_createdBy_users_id"
	}),
	recurringInvoiceAttachments: many(recurringInvoiceAttachments),
	retainerInvoiceAttachments: many(retainerInvoiceAttachments),
	inventoryStockCounts: many(inventoryStockCount),
	deliveryChallanAttachments: many(deliveryChallanAttachments),
	purchaseRequestApprovals: many(purchaseRequestApproval),
	inventoryAdjustmentAttachments: many(inventoryAdjustmentAttachments),
	paymentMadeAttachments: many(paymentMadeAttachments),
	expenses_createdBy: many(expenses, {
		relationName: "expenses_createdBy_users_id"
	}),
	expenses_updatedBy: many(expenses, {
		relationName: "expenses_updatedBy_users_id"
	}),
}));

export const productsRelations = relations(products, ({one, many}) => ({
	inventoryAdjustments: many(inventoryAdjustments),
	productContents: many(productContents),
	salesOrderItems: many(salesOrderItems),
	batchMasters: many(batchMaster),
	productBranchInventorySettings: many(productBranchInventorySettings),
	purchaseReceiveItems: many(purchaseReceiveItems),
	inventoryAdjustmentValueItems: many(inventoryAdjustmentValueItems),
	inventoryPackageItems: many(inventoryPackageItems),
	transferOrderItems: many(transferOrderItems),
	creditNoteItems: many(creditNoteItems),
	billItems: many(billItems),
	productEcommerces: many(productEcommerce),
	compositeItemParts: many(compositeItemParts),
	purchaseOrderItems: many(purchaseOrderItems),
	recurringInvoiceItems: many(recurringInvoiceItems),
	stockCountItems: many(stockCountItems),
	purchaseReceiveItemBatches: many(purchaseReceiveItemBatches),
	demandPools: many(demandPool),
	itemRegistrationRequests: many(itemRegistrationRequests),
	purchaseRequestItems: many(purchaseRequestItems),
	inventoryAdjustmentItems: many(inventoryAdjustmentItems),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	procurementSubstitutions_originalProductId: many(procurementSubstitutions, {
		relationName: "procurementSubstitutions_originalProductId_products_id"
	}),
	procurementSubstitutions_substituteProductId: many(procurementSubstitutions, {
		relationName: "procurementSubstitutions_substituteProductId_products_id"
	}),
	purchaseOrderRequestAllocations: many(purchaseOrderRequestAllocations),
	demandAllocations: many(demandAllocations),
	batchStockLayers: many(batchStockLayers),
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
	taxGroup_interStateTaxId: one(taxGroups, {
		fields: [products.interStateTaxId],
		references: [taxGroups.id],
		relationName: "products_interStateTaxId_taxGroups_id"
	}),
	taxGroup_intraStateTaxId: one(taxGroups, {
		fields: [products.intraStateTaxId],
		references: [taxGroups.id],
		relationName: "products_intraStateTaxId_taxGroups_id"
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
	productType: one(productTypes, {
		fields: [products.productTypeId],
		references: [productTypes.id]
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
	salesRep: one(salesReps, {
		fields: [products.repId],
		references: [salesReps.id]
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
	productPackSize: one(productPackSizes, {
		fields: [products.unitPackId],
		references: [productPackSizes.id]
	}),
	priceListItems: many(priceListItems),
	productEntitySettings: many(productEntitySettings),
	productBinMappings: many(productBinMappings),
	deliveryChallanItems: many(deliveryChallanItems),
	productVendorMappings: many(productVendorMappings),
}));

export const transactionLocksRelations = relations(transactionLocks, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [transactionLocks.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const invoiceMasterRelations = relations(invoiceMaster, ({one, many}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [invoiceMaster.entityId],
		references: [organisationBranchMaster.id]
	}),
	invoiceSalesOrders: many(invoiceSalesOrders),
	invoiceShipments: many(invoiceShipments),
	invoiceAttachments: many(invoiceAttachments),
	paymentReceivedAllocations: many(paymentReceivedAllocations),
	invoicePackages: many(invoicePackages),
	recurringInvoiceRuns: many(recurringInvoiceRuns),
	invoiceItems: many(invoiceItems),
	retainerInvoiceApplications: many(retainerInvoiceApplications),
}));

export const statesRelations = relations(states, ({one, many}) => ({
	country: one(countries, {
		fields: [states.stateId],
		references: [countries.id]
	}),
	lsgdDistricts: many(lsgdDistricts),
	organizations: many(organization),
}));

export const countriesRelations = relations(countries, ({one, many}) => ({
	states: many(states),
	timezone: one(timezones, {
		fields: [countries.primaryTimezoneId],
		references: [timezones.id],
		relationName: "countries_primaryTimezoneId_timezones_id"
	}),
	timezones: many(timezones, {
		relationName: "timezones_countryId_countries_id"
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
	drugSchedule: one(drugSchedules, {
		fields: [productContents.scheduleId],
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

export const drugSchedulesRelations = relations(drugSchedules, ({many}) => ({
	productContents: many(productContents),
	products: many(products),
}));

export const drugStrengthsRelations = relations(drugStrengths, ({many}) => ({
	productContents: many(productContents),
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
	billItems: many(billItems),
	inventoryPackages: many(inventoryPackages),
	branch: one(branches, {
		fields: [customers.associatedBranchId],
		references: [branches.id]
	}),
	currency: one(currencies, {
		fields: [customers.currencyId],
		references: [currencies.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [customers.entityId],
		references: [organisationBranchMaster.id]
	}),
	gstTreatment: one(gstTreatments, {
		fields: [customers.gstTreatment],
		references: [gstTreatments.code]
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
	customerContactPersons: many(customerContactPersons),
	creditNotes: many(creditNotes),
	paymentsReceiveds: many(paymentsReceived),
	recurringInvoices: many(recurringInvoices),
	warehouses: many(warehouses),
	inventoryShipments: many(inventoryShipments),
	retainerInvoices: many(retainerInvoices),
	recurringExpenses: many(recurringExpenses),
	salesReturns: many(salesReturns),
	deliveryChallans: many(deliveryChallans),
	customerAddresses: many(customerAddresses),
	expenses: many(expenses),
}));

export const salesOrderItemsRelations = relations(salesOrderItems, ({one, many}) => ({
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
	demandPools: many(demandPool),
	procurementSubstitutions: many(procurementSubstitutions),
}));

export const salesOrdersRelations = relations(salesOrders, ({one, many}) => ({
	salesOrderItems: many(salesOrderItems),
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
	demandPools: many(demandPool),
	procurementSubstitutions: many(procurementSubstitutions),
	picklistItems: many(picklistItems),
	inventoryShipmentSalesOrders: many(inventoryShipmentSalesOrders),
}));

export const batchMasterRelations = relations(batchMaster, ({one, many}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [batchMaster.createdByEntityId],
		references: [organisationBranchMaster.id]
	}),
	product: one(products, {
		fields: [batchMaster.productId],
		references: [products.id]
	}),
	inventoryAdjustmentValueItems: many(inventoryAdjustmentValueItems),
	salesReturnReceiveBatches: many(salesReturnReceiveBatches),
	vendorCreditItemBatches: many(vendorCreditItemBatches),
	inventoryAdjustmentItems: many(inventoryAdjustmentItems),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	invoiceItemBatches: many(invoiceItemBatches),
	creditNoteItemBatches: many(creditNoteItemBatches),
	billItemBatches: many(billItemBatches),
	batchStockLayers: many(batchStockLayers),
	deliveryChallanItemBatches: many(deliveryChallanItemBatches),
	transferOrderSourceBatches: many(transferOrderSourceBatches),
	purchaseReturnItemBatches: many(purchaseReturnItemBatches),
}));

export const purchaseOrderAttachmentsRelations = relations(purchaseOrderAttachments, ({one}) => ({
	purchaseOrder: one(purchaseOrders, {
		fields: [purchaseOrderAttachments.purchaseOrderId],
		references: [purchaseOrders.id]
	}),
}));

export const paymentTermsRelations = relations(paymentTerms, ({many}) => ({
	salesOrders: many(salesOrders),
	purchaseOrders: many(purchaseOrders),
	bills: many(bills),
	defaultPaymentTerms: many(defaultPaymentTerms),
}));

export const priceListsRelations = relations(priceLists, ({one, many}) => ({
	salesOrders: many(salesOrders),
	customers: many(customers),
	creditNotes: many(creditNotes),
	recurringInvoices: many(recurringInvoices),
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
	deliveryChallans: many(deliveryChallans),
	priceListItems: many(priceListItems),
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
	vendors: many(vendors),
	paymentMadeTaxes: many(paymentMadeTax),
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

export const reorderTermsRelations = relations(reorderTerms, ({one, many}) => ({
	productBranchInventorySettings: many(productBranchInventorySettings),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [reorderTerms.entityId],
		references: [organisationBranchMaster.id]
	}),
	compositeItems: many(compositeItems),
	products: many(products),
	productEntitySettings: many(productEntitySettings),
}));

export const categoriesRelations = relations(categories, ({one, many}) => ({
	category: one(categories, {
		fields: [categories.parentId],
		references: [categories.id],
		relationName: "categories_parentId_categories_id"
	}),
	categories: many(categories, {
		relationName: "categories_parentId_categories_id"
	}),
	compositeItems: many(compositeItems),
	purchaseRequestItems: many(purchaseRequestItems),
	products: many(products),
}));

export const billLandedCostsRelations = relations(billLandedCosts, ({one}) => ({
	bill: one(bills, {
		fields: [billLandedCosts.billId],
		references: [bills.id]
	}),
}));

export const billsRelations = relations(bills, ({one, many}) => ({
	billLandedCosts: many(billLandedCosts),
	billItems: many(billItems),
	vendorCredits: many(vendorCredits),
	vendorAddress: one(vendorAddresses, {
		fields: [bills.billingAddress],
		references: [vendorAddresses.id]
	}),
	account: one(accounts, {
		fields: [bills.discountAccountsId],
		references: [accounts.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [bills.entityId],
		references: [organisationBranchMaster.id]
	}),
	paymentTerm: one(paymentTerms, {
		fields: [bills.paymentTermId],
		references: [paymentTerms.id]
	}),
	vendor: one(vendors, {
		fields: [bills.vendorId],
		references: [vendors.id]
	}),
	warehouse: one(warehouses, {
		fields: [bills.warehouseId],
		references: [warehouses.id]
	}),
	purchaseReturns: many(purchaseReturns),
	billAttachments: many(billAttachments),
	paymentMadeBillAllocations: many(paymentMadeBillAllocations),
	vendorAdvanceAllocations: many(vendorAdvanceAllocations),
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
	billItems: many(billItems),
	purchaseReceiveItemBatches: many(purchaseReceiveItemBatches),
}));

export const binMasterRelations = relations(binMaster, ({one, many}) => ({
	purchaseReceiveItems: many(purchaseReceiveItems),
	picklistBatchAllocations: many(picklistBatchAllocation),
	salesReturnReceiveBatches: many(salesReturnReceiveBatches),
	warehouse: one(warehouses, {
		fields: [binMaster.warehouseId],
		references: [warehouses.id]
	}),
	zoneMaster: one(zoneMaster, {
		fields: [binMaster.zoneId],
		references: [zoneMaster.id]
	}),
	purchaseReceiveItemBatches: many(purchaseReceiveItemBatches),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	transferOrderDestinationBatches: many(transferOrderDestinationBatches),
	creditNoteItemBatches: many(creditNoteItemBatches),
	billItemBatches: many(billItemBatches),
	batchStockLayers: many(batchStockLayers),
	deliveryChallanItemBatches: many(deliveryChallanItemBatches),
	transferOrderSourceBatches: many(transferOrderSourceBatches),
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
	journalEntry: one(journalEntries, {
		fields: [accountTransactions.journalEntryId],
		references: [journalEntries.id]
	}),
}));

export const inventoryMoveOrderDestinationBinsRelations = relations(inventoryMoveOrderDestinationBins, ({one}) => ({
	inventoryMoveOrderSourceBatch: one(inventoryMoveOrderSourceBatches, {
		fields: [inventoryMoveOrderDestinationBins.sourceBatchRowId],
		references: [inventoryMoveOrderSourceBatches.id]
	}),
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
	journalEntry: one(journalEntries, {
		fields: [manualJournals.ledgerJournalEntryId],
		references: [journalEntries.id]
	}),
	manualJournalAttachments: many(manualJournalAttachments),
	manualJournalItems: many(manualJournalItems),
}));

export const recurringJournalsRelations = relations(recurringJournals, ({one, many}) => ({
	manualJournals: many(manualJournals),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [recurringJournals.entityId],
		references: [organisationBranchMaster.id]
	}),
	recurringJournalItems: many(recurringJournalItems),
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

export const picklistMasterRelations = relations(picklistMaster, ({one, many}) => ({
	warehouse: one(warehouses, {
		fields: [picklistMaster.warehouseId],
		references: [warehouses.id]
	}),
	inventoryPackageItems: many(inventoryPackageItems),
	picklistItems: many(picklistItems),
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

export const inventoryPackagesRelations = relations(inventoryPackages, ({one, many}) => ({
	inventoryPackageItems: many(inventoryPackageItems),
	customer: one(customers, {
		fields: [inventoryPackages.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryPackages.entityId],
		references: [organisationBranchMaster.id]
	}),
	invoicePackages: many(invoicePackages),
	inventoryShipmentPackages: many(inventoryShipmentPackages),
	inventoryPackageSalesOrders: many(inventoryPackageSalesOrders),
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
	transferOrderDestinationBatches: many(transferOrderDestinationBatches),
	transferOrderSourceBatches: many(transferOrderSourceBatches),
}));

export const transferOrderMasterRelations = relations(transferOrderMaster, ({one, many}) => ({
	transferOrderItems: many(transferOrderItems),
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
	transferOrderLogs: many(transferOrderLogs),
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

export const picklistItemsRelations = relations(picklistItems, ({one, many}) => ({
	picklistBatchAllocations: many(picklistBatchAllocation),
	picklistMaster: one(picklistMaster, {
		fields: [picklistItems.picklistId],
		references: [picklistMaster.id]
	}),
	salesOrder: one(salesOrders, {
		fields: [picklistItems.salesOrderId],
		references: [salesOrders.id]
	}),
}));

export const vendorContactPersonsRelations = relations(vendorContactPersons, ({one}) => ({
	vendor: one(vendors, {
		fields: [vendorContactPersons.vendorId],
		references: [vendors.id]
	}),
}));

export const vendorsRelations = relations(vendors, ({one, many}) => ({
	vendorContactPersons: many(vendorContactPersons),
	purchaseOrders: many(purchaseOrders),
	vendorBankAccounts: many(vendorBankAccounts),
	warehouses: many(warehouses),
	recurringExpenses: many(recurringExpenses),
	vendorCredits: many(vendorCredits),
	bills: many(bills),
	demandPools_preferredVendorId: many(demandPool, {
		relationName: "demandPool_preferredVendorId_vendors_id"
	}),
	demandPools_selectedVendorId: many(demandPool, {
		relationName: "demandPool_selectedVendorId_vendors_id"
	}),
	itemRegistrationRequests: many(itemRegistrationRequests),
	purchaseReturns: many(purchaseReturns),
	purchaseRequestItems_preferredVendorId: many(purchaseRequestItems, {
		relationName: "purchaseRequestItems_preferredVendorId_vendors_id"
	}),
	purchaseRequestItems_selectedVendorId: many(purchaseRequestItems, {
		relationName: "purchaseRequestItems_selectedVendorId_vendors_id"
	}),
	vendorAddresses: many(vendorAddresses),
	purchaseRequestVendorChecks: many(purchaseRequestVendorChecks),
	procurementSubstitutions: many(procurementSubstitutions),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [vendors.entityId],
		references: [organisationBranchMaster.id]
	}),
	tdsRate: one(tdsRates, {
		fields: [vendors.tdsRateId],
		references: [tdsRates.id]
	}),
	paymentMadeMasters: many(paymentMadeMaster),
	batchStockLayers: many(batchStockLayers),
	products: many(products),
	productEntitySettings: many(productEntitySettings),
	expenses: many(expenses),
}));

export const vendorAddressesRelations = relations(vendorAddresses, ({one, many}) => ({
	purchaseOrders_billingAddress: many(purchaseOrders, {
		relationName: "purchaseOrders_billingAddress_vendorAddresses_id"
	}),
	purchaseOrders_shippingAddress: many(purchaseOrders, {
		relationName: "purchaseOrders_shippingAddress_vendorAddresses_id"
	}),
	bills: many(bills),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [vendorAddresses.entityId],
		references: [organisationBranchMaster.id]
	}),
	vendor: one(vendors, {
		fields: [vendorAddresses.vendorId],
		references: [vendors.id]
	}),
}));

export const carrierRelations = relations(carrier, ({many}) => ({
	purchaseOrders: many(purchaseOrders),
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

export const creditNotesRelations = relations(creditNotes, ({one, many}) => ({
	creditNoteItems: many(creditNoteItems),
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

export const billItemsRelations = relations(billItems, ({one, many}) => ({
	account_accountId: one(accounts, {
		fields: [billItems.accountId],
		references: [accounts.id],
		relationName: "billItems_accountId_accounts_id"
	}),
	bill: one(bills, {
		fields: [billItems.billId],
		references: [bills.id]
	}),
	customer: one(customers, {
		fields: [billItems.customerId],
		references: [customers.id]
	}),
	account_discountAccountsId: one(accounts, {
		fields: [billItems.discountAccountsId],
		references: [accounts.id],
		relationName: "billItems_discountAccountsId_accounts_id"
	}),
	product: one(products, {
		fields: [billItems.productId],
		references: [products.id]
	}),
	purchaseReceiveItem: one(purchaseReceiveItems, {
		fields: [billItems.purchaseReceiveItemId],
		references: [purchaseReceiveItems.id]
	}),
	taxGroup: one(taxGroups, {
		fields: [billItems.taxId],
		references: [taxGroups.id]
	}),
	billItemBatches: many(billItemBatches),
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

export const unitsRelations = relations(units, ({one, many}) => ({
	uqc: one(uqc, {
		fields: [units.uqcId],
		references: [uqc.id]
	}),
	compositeItems: many(compositeItems),
	unitGroups: many(unitGroups),
	unitGroupConversions: many(unitGroupConversions),
	products: many(products),
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

export const productEcommerceRelations = relations(productEcommerce, ({one}) => ({
	product: one(products, {
		fields: [productEcommerce.productId],
		references: [products.id]
	}),
}));

export const compositeItemsRelations = relations(compositeItems, ({one, many}) => ({
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
	compositeItemParts: many(compositeItemParts),
}));

export const brandsRelations = relations(brands, ({many}) => ({
	compositeItems: many(compositeItems),
	salesReps: many(salesReps),
	products: many(products),
}));

export const manufacturersRelations = relations(manufacturers, ({many}) => ({
	compositeItems: many(compositeItems),
	products: many(products),
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
	branchPriceListAssignments: many(branchPriceListAssignments),
}));

export const currenciesRelations = relations(currencies, ({many}) => ({
	customers: many(customers),
	currencyExchangeRates: many(currencyExchangeRates),
}));

export const gstTreatmentsRelations = relations(gstTreatments, ({many}) => ({
	customers: many(customers),
	branches: many(branches),
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

export const batchStockLayersRelations = relations(batchStockLayers, ({one, many}) => ({
	salesReturnReceiveBatches: many(salesReturnReceiveBatches),
	vendorCreditItemBatches: many(vendorCreditItemBatches),
	inventoryAdjustmentItemBatches: many(inventoryAdjustmentItemBatches),
	invoiceItemBatches: many(invoiceItemBatches),
	creditNoteItemBatches: many(creditNoteItemBatches),
	billItemBatches: many(billItemBatches),
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
	deliveryChallanItemBatches: many(deliveryChallanItemBatches),
	transferOrderSourceBatches: many(transferOrderSourceBatches),
	purchaseReturnItemBatches: many(purchaseReturnItemBatches),
}));

export const salesReturnReceiveItemsRelations = relations(salesReturnReceiveItems, ({one, many}) => ({
	salesReturnReceiveBatches: many(salesReturnReceiveBatches),
	salesReturnReceive: one(salesReturnReceives, {
		fields: [salesReturnReceiveItems.salesReturnReceiveId],
		references: [salesReturnReceives.id]
	}),
	salesReturnItem: one(salesReturnItems, {
		fields: [salesReturnReceiveItems.salesReturnItemId],
		references: [salesReturnItems.id]
	}),
}));

export const vendorCreditItemBatchesRelations = relations(vendorCreditItemBatches, ({one}) => ({
	vendorCreditItem: one(vendorCreditItems, {
		fields: [vendorCreditItemBatches.vendorCreditItemId],
		references: [vendorCreditItems.id]
	}),
	batchStockLayer: one(batchStockLayers, {
		fields: [vendorCreditItemBatches.layerId],
		references: [batchStockLayers.id]
	}),
	batchMaster: one(batchMaster, {
		fields: [vendorCreditItemBatches.batchId],
		references: [batchMaster.id]
	}),
}));

export const vendorCreditItemsRelations = relations(vendorCreditItems, ({one, many}) => ({
	vendorCreditItemBatches: many(vendorCreditItemBatches),
	vendorCredit: one(vendorCredits, {
		fields: [vendorCreditItems.vendorCreditId],
		references: [vendorCredits.id]
	}),
}));

export const expenseItemsRelations = relations(expenseItems, ({one}) => ({
	account: one(accounts, {
		fields: [expenseItems.expenseAccountId],
		references: [accounts.id]
	}),
	expense: one(expenses, {
		fields: [expenseItems.expenseId],
		references: [expenses.id]
	}),
	taxRate: one(taxRates, {
		fields: [expenseItems.taxId],
		references: [taxRates.id]
	}),
}));

export const expensesRelations = relations(expenses, ({one, many}) => ({
	expenseItems: many(expenseItems),
	expenseAttachments: many(expenseAttachments),
	expenseMileages: many(expenseMileage),
	user_createdBy: one(users, {
		fields: [expenses.createdBy],
		references: [users.id],
		relationName: "expenses_createdBy_users_id"
	}),
	customer: one(customers, {
		fields: [expenses.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [expenses.entityId],
		references: [organisationBranchMaster.id]
	}),
	account_expenseAccountId: one(accounts, {
		fields: [expenses.expenseAccountId],
		references: [accounts.id],
		relationName: "expenses_expenseAccountId_accounts_id"
	}),
	account_paidThroughAccountId: one(accounts, {
		fields: [expenses.paidThroughAccountId],
		references: [accounts.id],
		relationName: "expenses_paidThroughAccountId_accounts_id"
	}),
	recurringExpense: one(recurringExpenses, {
		fields: [expenses.recurringExpenseId],
		references: [recurringExpenses.id]
	}),
	taxRate: one(taxRates, {
		fields: [expenses.taxId],
		references: [taxRates.id]
	}),
	user_updatedBy: one(users, {
		fields: [expenses.updatedBy],
		references: [users.id],
		relationName: "expenses_updatedBy_users_id"
	}),
	vendor: one(vendors, {
		fields: [expenses.vendorId],
		references: [vendors.id]
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
	warehouses: many(warehouses),
}));

export const paymentsReceivedRelations = relations(paymentsReceived, ({one, many}) => ({
	customer: one(customers, {
		fields: [paymentsReceived.customerId],
		references: [customers.id]
	}),
	account: one(accounts, {
		fields: [paymentsReceived.depositAccountId],
		references: [accounts.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [paymentsReceived.entityId],
		references: [organisationBranchMaster.id]
	}),
	paymentReceivedAllocations: many(paymentReceivedAllocations),
	paymentReceivedAttachments: many(paymentReceivedAttachments),
}));

export const businessTypesRelations = relations(businessTypes, ({many}) => ({
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

export const paymentReceivedAllocationsRelations = relations(paymentReceivedAllocations, ({one}) => ({
	invoiceMaster: one(invoiceMaster, {
		fields: [paymentReceivedAllocations.invoiceId],
		references: [invoiceMaster.id]
	}),
	paymentsReceived: one(paymentsReceived, {
		fields: [paymentReceivedAllocations.paymentReceivedId],
		references: [paymentsReceived.id]
	}),
}));

export const reportingTagsRelations = relations(reportingTags, ({one, many}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [reportingTags.entityId],
		references: [organisationBranchMaster.id]
	}),
	reportingTagOptions: many(reportingTagOptions),
	reportingTagModuleMappings: many(reportingTagModuleMappings),
	manualJournalTagMappings: many(manualJournalTagMappings),
}));

export const paymentReceivedAttachmentsRelations = relations(paymentReceivedAttachments, ({one}) => ({
	paymentsReceived: one(paymentsReceived, {
		fields: [paymentReceivedAttachments.paymentReceivedId],
		references: [paymentsReceived.id]
	}),
}));

export const expenseAttachmentsRelations = relations(expenseAttachments, ({one}) => ({
	expense: one(expenses, {
		fields: [expenseAttachments.expenseId],
		references: [expenses.id]
	}),
	user: one(users, {
		fields: [expenseAttachments.uploadedBy],
		references: [users.id]
	}),
}));

export const recurringInvoicesRelations = relations(recurringInvoices, ({one, many}) => ({
	user_createdBy: one(users, {
		fields: [recurringInvoices.createdBy],
		references: [users.id],
		relationName: "recurringInvoices_createdBy_users_id"
	}),
	customer: one(customers, {
		fields: [recurringInvoices.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [recurringInvoices.entityId],
		references: [organisationBranchMaster.id]
	}),
	priceList: one(priceLists, {
		fields: [recurringInvoices.priceListId],
		references: [priceLists.id]
	}),
	user_salespersonId: one(users, {
		fields: [recurringInvoices.salespersonId],
		references: [users.id],
		relationName: "recurringInvoices_salespersonId_users_id"
	}),
	user_updatedBy: one(users, {
		fields: [recurringInvoices.updatedBy],
		references: [users.id],
		relationName: "recurringInvoices_updatedBy_users_id"
	}),
	warehouse: one(warehouses, {
		fields: [recurringInvoices.warehouseId],
		references: [warehouses.id]
	}),
	recurringInvoiceItems: many(recurringInvoiceItems),
	recurringInvoiceRuns: many(recurringInvoiceRuns),
	recurringInvoiceAttachments: many(recurringInvoiceAttachments),
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

export const transferOrderLogsRelations = relations(transferOrderLogs, ({one}) => ({
	transferOrderMaster: one(transferOrderMaster, {
		fields: [transferOrderLogs.transferOrderId],
		references: [transferOrderMaster.id]
	}),
}));

export const purchaseReceiveAttachmentsRelations = relations(purchaseReceiveAttachments, ({one}) => ({
	purchaseReceive: one(purchaseReceives, {
		fields: [purchaseReceiveAttachments.purchaseReceiveId],
		references: [purchaseReceives.id]
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

export const expenseMileageRelations = relations(expenseMileage, ({one}) => ({
	user: one(users, {
		fields: [expenseMileage.employeeId],
		references: [users.id]
	}),
	expense: one(expenses, {
		fields: [expenseMileage.expenseId],
		references: [expenses.id]
	}),
}));

export const salesRepsRelations = relations(salesReps, ({one, many}) => ({
	brand: one(brands, {
		fields: [salesReps.brandId],
		references: [brands.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [salesReps.entityId],
		references: [organisationBranchMaster.id]
	}),
	products: many(products),
}));

export const moveOrderAttachmentsRelations = relations(moveOrderAttachments, ({one}) => ({
	inventoryMoveOrder: one(inventoryMoveOrders, {
		fields: [moveOrderAttachments.moveOrderId],
		references: [inventoryMoveOrders.id]
	}),
}));

export const inventoryMoveOrdersRelations = relations(inventoryMoveOrders, ({many}) => ({
	moveOrderAttachments: many(moveOrderAttachments),
	inventoryMoveOrderItems: many(inventoryMoveOrderItems),
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

export const recurringInvoiceItemsRelations = relations(recurringInvoiceItems, ({one}) => ({
	account: one(accounts, {
		fields: [recurringInvoiceItems.accounts],
		references: [accounts.id]
	}),
	recurringInvoice: one(recurringInvoices, {
		fields: [recurringInvoiceItems.recurringInvoiceId],
		references: [recurringInvoices.id]
	}),
	product: one(products, {
		fields: [recurringInvoiceItems.productId],
		references: [products.id]
	}),
	taxRate: one(taxRates, {
		fields: [recurringInvoiceItems.taxId],
		references: [taxRates.id]
	}),
}));

export const retainerInvoicesRelations = relations(retainerInvoices, ({one, many}) => ({
	customer: one(customers, {
		fields: [retainerInvoices.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [retainerInvoices.entityId],
		references: [organisationBranchMaster.id]
	}),
	retainerInvoiceItems: many(retainerInvoiceItems),
	retainerInvoiceAttachments: many(retainerInvoiceAttachments),
	retainerInvoiceApplications: many(retainerInvoiceApplications),
}));

export const recurringExpensesRelations = relations(recurringExpenses, ({one, many}) => ({
	customer: one(customers, {
		fields: [recurringExpenses.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [recurringExpenses.entityId],
		references: [organisationBranchMaster.id]
	}),
	account_expenseAccountId: one(accounts, {
		fields: [recurringExpenses.expenseAccountId],
		references: [accounts.id],
		relationName: "recurringExpenses_expenseAccountId_accounts_id"
	}),
	account_paidThroughAccountId: one(accounts, {
		fields: [recurringExpenses.paidThroughAccountId],
		references: [accounts.id],
		relationName: "recurringExpenses_paidThroughAccountId_accounts_id"
	}),
	vendor: one(vendors, {
		fields: [recurringExpenses.vendorId],
		references: [vendors.id]
	}),
	recurringExpenseReceipts: many(recurringExpenseReceipts),
	recurringExpenseRuns: many(recurringExpenseRuns),
	expenses: many(expenses),
}));

export const stockCountItemsRelations = relations(stockCountItems, ({one}) => ({
	product: one(products, {
		fields: [stockCountItems.productId],
		references: [products.id]
	}),
}));

export const vendorCreditsRelations = relations(vendorCredits, ({one, many}) => ({
	bill: one(bills, {
		fields: [vendorCredits.billId],
		references: [bills.id]
	}),
	purchaseReturn: one(purchaseReturns, {
		fields: [vendorCredits.purchaseReturnId],
		references: [purchaseReturns.id]
	}),
	vendor: one(vendors, {
		fields: [vendorCredits.vendorId],
		references: [vendors.id]
	}),
	vendorCreditItems: many(vendorCreditItems),
	vendorCreditsAttachments: many(vendorCreditsAttachments),
}));

export const purchaseReturnsRelations = relations(purchaseReturns, ({one, many}) => ({
	vendorCredits: many(vendorCredits),
	bill: one(bills, {
		fields: [purchaseReturns.billId],
		references: [bills.id]
	}),
	vendor: one(vendors, {
		fields: [purchaseReturns.vendorId],
		references: [vendors.id]
	}),
	purchaseReturnItems: many(purchaseReturnItems),
}));

export const generalPreferencesRelations = relations(generalPreferences, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [generalPreferences.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const recurringExpenseReceiptsRelations = relations(recurringExpenseReceipts, ({one}) => ({
	recurringExpense: one(recurringExpenses, {
		fields: [recurringExpenseReceipts.recurringExpenseId],
		references: [recurringExpenses.id]
	}),
}));

export const branchPriceListAssignmentsRelations = relations(branchPriceListAssignments, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [branchPriceListAssignments.branchEntityId],
		references: [organisationBranchMaster.id]
	}),
	branch: one(branches, {
		fields: [branchPriceListAssignments.branchId],
		references: [branches.id]
	}),
	priceList: one(priceLists, {
		fields: [branchPriceListAssignments.priceListId],
		references: [priceLists.id]
	}),
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

export const currencyExchangeRatesRelations = relations(currencyExchangeRates, ({one}) => ({
	currency: one(currencies, {
		fields: [currencyExchangeRates.currencyId],
		references: [currencies.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [currencyExchangeRates.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const recurringInvoiceRunsRelations = relations(recurringInvoiceRuns, ({one}) => ({
	invoiceMaster: one(invoiceMaster, {
		fields: [recurringInvoiceRuns.generatedInvoiceId],
		references: [invoiceMaster.id]
	}),
	recurringInvoice: one(recurringInvoices, {
		fields: [recurringInvoiceRuns.recurringInvoiceId],
		references: [recurringInvoices.id]
	}),
}));

export const demandPoolRelations = relations(demandPool, ({one, many}) => ({
	user_createdBy: one(users, {
		fields: [demandPool.createdBy],
		references: [users.id],
		relationName: "demandPool_createdBy_users_id"
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [demandPool.entityId],
		references: [organisationBranchMaster.id]
	}),
	vendor_preferredVendorId: one(vendors, {
		fields: [demandPool.preferredVendorId],
		references: [vendors.id],
		relationName: "demandPool_preferredVendorId_vendors_id"
	}),
	product: one(products, {
		fields: [demandPool.productId],
		references: [products.id]
	}),
	purchaseRequest: one(purchaseRequests, {
		fields: [demandPool.purchaseRequestId],
		references: [purchaseRequests.id]
	}),
	salesOrder: one(salesOrders, {
		fields: [demandPool.salesOrderId],
		references: [salesOrders.id]
	}),
	salesOrderItem: one(salesOrderItems, {
		fields: [demandPool.salesOrderItemId],
		references: [salesOrderItems.id]
	}),
	vendor_selectedVendorId: one(vendors, {
		fields: [demandPool.selectedVendorId],
		references: [vendors.id],
		relationName: "demandPool_selectedVendorId_vendors_id"
	}),
	user_updatedBy: one(users, {
		fields: [demandPool.updatedBy],
		references: [users.id],
		relationName: "demandPool_updatedBy_users_id"
	}),
	warehouse: one(warehouses, {
		fields: [demandPool.warehouseId],
		references: [warehouses.id]
	}),
	purchaseRequestItems: many(purchaseRequestItems),
	procurementSubstitutions: many(procurementSubstitutions),
	purchaseOrderRequestAllocations: many(purchaseOrderRequestAllocations),
	demandAllocations: many(demandAllocations),
}));

export const purchaseRequestsRelations = relations(purchaseRequests, ({one, many}) => ({
	demandPools: many(demandPool),
	user_approvedBy: one(users, {
		fields: [purchaseRequests.approvedBy],
		references: [users.id],
		relationName: "purchaseRequests_approvedBy_users_id"
	}),
	user_assigneeId: one(users, {
		fields: [purchaseRequests.assigneeId],
		references: [users.id],
		relationName: "purchaseRequests_assigneeId_users_id"
	}),
	user_createdBy: one(users, {
		fields: [purchaseRequests.createdBy],
		references: [users.id],
		relationName: "purchaseRequests_createdBy_users_id"
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [purchaseRequests.entityId],
		references: [organisationBranchMaster.id]
	}),
	warehouse: one(warehouses, {
		fields: [purchaseRequests.warehouseId],
		references: [warehouses.id]
	}),
	purchaseRequestItems: many(purchaseRequestItems),
	procurementSubstitutions: many(procurementSubstitutions),
	purchaseOrderRequestAllocations: many(purchaseOrderRequestAllocations),
	purchaseRequestApprovals: many(purchaseRequestApproval),
}));

export const unitGroupsRelations = relations(unitGroups, ({one, many}) => ({
	unit: one(units, {
		fields: [unitGroups.baseUnitId],
		references: [units.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [unitGroups.entityId],
		references: [organisationBranchMaster.id]
	}),
	unitGroupConversions: many(unitGroupConversions),
}));

export const itemRegistrationRequestsRelations = relations(itemRegistrationRequests, ({one}) => ({
	user_assignedTo: one(users, {
		fields: [itemRegistrationRequests.assignedTo],
		references: [users.id],
		relationName: "itemRegistrationRequests_assignedTo_users_id"
	}),
	user_completedBy: one(users, {
		fields: [itemRegistrationRequests.completedBy],
		references: [users.id],
		relationName: "itemRegistrationRequests_completedBy_users_id"
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [itemRegistrationRequests.entityId],
		references: [organisationBranchMaster.id]
	}),
	user_requestedBy: one(users, {
		fields: [itemRegistrationRequests.requestedBy],
		references: [users.id],
		relationName: "itemRegistrationRequests_requestedBy_users_id"
	}),
	product: one(products, {
		fields: [itemRegistrationRequests.tempProductId],
		references: [products.id]
	}),
	vendor: one(vendors, {
		fields: [itemRegistrationRequests.vendorId],
		references: [vendors.id]
	}),
}));

export const purchaseRequestItemsRelations = relations(purchaseRequestItems, ({one, many}) => ({
	category: one(categories, {
		fields: [purchaseRequestItems.categoryId],
		references: [categories.id]
	}),
	demandPool: one(demandPool, {
		fields: [purchaseRequestItems.demandPoolId],
		references: [demandPool.id]
	}),
	vendor_preferredVendorId: one(vendors, {
		fields: [purchaseRequestItems.preferredVendorId],
		references: [vendors.id],
		relationName: "purchaseRequestItems_preferredVendorId_vendors_id"
	}),
	product: one(products, {
		fields: [purchaseRequestItems.productId],
		references: [products.id]
	}),
	purchaseRequest: one(purchaseRequests, {
		fields: [purchaseRequestItems.purchaseRequestId],
		references: [purchaseRequests.id]
	}),
	vendor_selectedVendorId: one(vendors, {
		fields: [purchaseRequestItems.selectedVendorId],
		references: [vendors.id],
		relationName: "purchaseRequestItems_selectedVendorId_vendors_id"
	}),
	purchaseRequestVendorChecks: many(purchaseRequestVendorChecks),
	procurementSubstitutions: many(procurementSubstitutions),
	purchaseOrderRequestAllocations: many(purchaseOrderRequestAllocations),
}));

export const billAttachmentsRelations = relations(billAttachments, ({one}) => ({
	bill: one(bills, {
		fields: [billAttachments.billId],
		references: [bills.id]
	}),
}));

export const unitGroupConversionsRelations = relations(unitGroupConversions, ({one}) => ({
	unit: one(units, {
		fields: [unitGroupConversions.targetUnitId],
		references: [units.id]
	}),
	unitGroup: one(unitGroups, {
		fields: [unitGroupConversions.unitGroupId],
		references: [unitGroups.id]
	}),
}));

export const purchaseRequestVendorChecksRelations = relations(purchaseRequestVendorChecks, ({one}) => ({
	user: one(users, {
		fields: [purchaseRequestVendorChecks.checkedBy],
		references: [users.id]
	}),
	purchaseRequestItem: one(purchaseRequestItems, {
		fields: [purchaseRequestVendorChecks.purchaseRequestItemId],
		references: [purchaseRequestItems.id]
	}),
	vendor: one(vendors, {
		fields: [purchaseRequestVendorChecks.vendorId],
		references: [vendors.id]
	}),
}));

export const tcsRatesRelations = relations(tcsRates, ({one}) => ({
	tcsHigherRateReason: one(tcsHigherRateReasons, {
		fields: [tcsRates.higherRateReasonId],
		references: [tcsHigherRateReasons.id]
	}),
	tcsNature: one(tcsNatures, {
		fields: [tcsRates.natureId],
		references: [tcsNatures.id]
	}),
	account_payableAccountId: one(accounts, {
		fields: [tcsRates.payableAccountId],
		references: [accounts.id],
		relationName: "tcsRates_payableAccountId_accounts_id"
	}),
	account_receivableAccountId: one(accounts, {
		fields: [tcsRates.receivableAccountId],
		references: [accounts.id],
		relationName: "tcsRates_receivableAccountId_accounts_id"
	}),
}));

export const tcsHigherRateReasonsRelations = relations(tcsHigherRateReasons, ({many}) => ({
	tcsRates: many(tcsRates),
}));

export const tcsNaturesRelations = relations(tcsNatures, ({many}) => ({
	tcsRates: many(tcsRates),
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

export const procurementSubstitutionsRelations = relations(procurementSubstitutions, ({one}) => ({
	user_approvedBy: one(users, {
		fields: [procurementSubstitutions.approvedBy],
		references: [users.id],
		relationName: "procurementSubstitutions_approvedBy_users_id"
	}),
	user_createdBy: one(users, {
		fields: [procurementSubstitutions.createdBy],
		references: [users.id],
		relationName: "procurementSubstitutions_createdBy_users_id"
	}),
	demandPool: one(demandPool, {
		fields: [procurementSubstitutions.demandPoolId],
		references: [demandPool.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [procurementSubstitutions.entityId],
		references: [organisationBranchMaster.id]
	}),
	product_originalProductId: one(products, {
		fields: [procurementSubstitutions.originalProductId],
		references: [products.id],
		relationName: "procurementSubstitutions_originalProductId_products_id"
	}),
	purchaseRequest: one(purchaseRequests, {
		fields: [procurementSubstitutions.purchaseRequestId],
		references: [purchaseRequests.id]
	}),
	purchaseRequestItem: one(purchaseRequestItems, {
		fields: [procurementSubstitutions.purchaseRequestItemId],
		references: [purchaseRequestItems.id]
	}),
	salesOrder: one(salesOrders, {
		fields: [procurementSubstitutions.salesOrderId],
		references: [salesOrders.id]
	}),
	salesOrderItem: one(salesOrderItems, {
		fields: [procurementSubstitutions.salesOrderItemId],
		references: [salesOrderItems.id]
	}),
	product_substituteProductId: one(products, {
		fields: [procurementSubstitutions.substituteProductId],
		references: [products.id],
		relationName: "procurementSubstitutions_substituteProductId_products_id"
	}),
	vendor: one(vendors, {
		fields: [procurementSubstitutions.vendorId],
		references: [vendors.id]
	}),
	warehouse: one(warehouses, {
		fields: [procurementSubstitutions.warehouseId],
		references: [warehouses.id]
	}),
}));

export const reportingTagOptionsRelations = relations(reportingTagOptions, ({one, many}) => ({
	reportingTagOption: one(reportingTagOptions, {
		fields: [reportingTagOptions.parentOptionId],
		references: [reportingTagOptions.id],
		relationName: "reportingTagOptions_parentOptionId_reportingTagOptions_id"
	}),
	reportingTagOptions: many(reportingTagOptions, {
		relationName: "reportingTagOptions_parentOptionId_reportingTagOptions_id"
	}),
	reportingTag: one(reportingTags, {
		fields: [reportingTagOptions.reportingTagId],
		references: [reportingTags.id]
	}),
}));

export const reportingTagModuleMappingsRelations = relations(reportingTagModuleMappings, ({one}) => ({
	reportingTag: one(reportingTags, {
		fields: [reportingTagModuleMappings.reportingTagId],
		references: [reportingTags.id]
	}),
}));

export const purchaseOrderRequestAllocationsRelations = relations(purchaseOrderRequestAllocations, ({one}) => ({
	demandPool: one(demandPool, {
		fields: [purchaseOrderRequestAllocations.demandPoolId],
		references: [demandPool.id]
	}),
	purchaseRequest: one(purchaseRequests, {
		fields: [purchaseOrderRequestAllocations.purchaseRequestId],
		references: [purchaseRequests.id]
	}),
	purchaseRequestItem: one(purchaseRequestItems, {
		fields: [purchaseOrderRequestAllocations.purchaseRequestItemId],
		references: [purchaseRequestItems.id]
	}),
	product: one(products, {
		fields: [purchaseOrderRequestAllocations.productId],
		references: [products.id]
	}),
}));

export const demandAllocationsRelations = relations(demandAllocations, ({one}) => ({
	demandPool: one(demandPool, {
		fields: [demandAllocations.demandPoolId],
		references: [demandPool.id]
	}),
	product: one(products, {
		fields: [demandAllocations.productId],
		references: [products.id]
	}),
}));

export const recurringExpenseRunsRelations = relations(recurringExpenseRuns, ({one}) => ({
	recurringExpense: one(recurringExpenses, {
		fields: [recurringExpenseRuns.recurringExpenseId],
		references: [recurringExpenses.id]
	}),
}));

export const recurringInvoiceAttachmentsRelations = relations(recurringInvoiceAttachments, ({one}) => ({
	recurringInvoice: one(recurringInvoices, {
		fields: [recurringInvoiceAttachments.recurringInvoiceId],
		references: [recurringInvoices.id]
	}),
	user: one(users, {
		fields: [recurringInvoiceAttachments.uploadedBy],
		references: [users.id]
	}),
}));

export const retainerInvoiceItemsRelations = relations(retainerInvoiceItems, ({one}) => ({
	retainerInvoice: one(retainerInvoices, {
		fields: [retainerInvoiceItems.retainerInvoiceId],
		references: [retainerInvoices.id]
	}),
}));

export const paymentMadePaymentModeRelations = relations(paymentMadePaymentMode, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [paymentMadePaymentMode.entityId],
		references: [organisationBranchMaster.id]
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

export const priceListVolumeRangesRelations = relations(priceListVolumeRanges, ({one}) => ({
	priceListItem: one(priceListItems, {
		fields: [priceListVolumeRanges.priceListItemId],
		references: [priceListItems.id]
	}),
}));

export const priceListItemsRelations = relations(priceListItems, ({one, many}) => ({
	priceListVolumeRanges: many(priceListVolumeRanges),
	priceList: one(priceLists, {
		fields: [priceListItems.priceListId],
		references: [priceLists.id]
	}),
	product: one(products, {
		fields: [priceListItems.productId],
		references: [products.id]
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

export const invoiceItemsRelations = relations(invoiceItems, ({one, many}) => ({
	invoiceItemBatches: many(invoiceItemBatches),
	account: one(accounts, {
		fields: [invoiceItems.accounts],
		references: [accounts.id]
	}),
	invoiceMaster: one(invoiceMaster, {
		fields: [invoiceItems.invoiceId],
		references: [invoiceMaster.id]
	}),
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

export const paymentMadeMasterRelations = relations(paymentMadeMaster, ({one, many}) => ({
	account_depositToAccountId: one(accounts, {
		fields: [paymentMadeMaster.depositToAccountId],
		references: [accounts.id],
		relationName: "paymentMadeMaster_depositToAccountId_accounts_id"
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [paymentMadeMaster.entityId],
		references: [organisationBranchMaster.id]
	}),
	account_paidThroughAccountId: one(accounts, {
		fields: [paymentMadeMaster.paidThroughAccountId],
		references: [accounts.id],
		relationName: "paymentMadeMaster_paidThroughAccountId_accounts_id"
	}),
	vendor: one(vendors, {
		fields: [paymentMadeMaster.vendorId],
		references: [vendors.id]
	}),
	paymentMadeTaxes: many(paymentMadeTax),
	paymentMadeBillAllocations: many(paymentMadeBillAllocations),
	vendorAdvanceAllocations: many(vendorAdvanceAllocations),
	paymentMadeAttachments: many(paymentMadeAttachments),
}));

export const retainerInvoiceAttachmentsRelations = relations(retainerInvoiceAttachments, ({one}) => ({
	retainerInvoice: one(retainerInvoices, {
		fields: [retainerInvoiceAttachments.retainerInvoiceId],
		references: [retainerInvoices.id]
	}),
	user: one(users, {
		fields: [retainerInvoiceAttachments.uploadedBy],
		references: [users.id]
	}),
}));

export const salesReturnItemsRelations = relations(salesReturnItems, ({one, many}) => ({
	salesReturnReceiveItems: many(salesReturnReceiveItems),
	salesReturn: one(salesReturns, {
		fields: [salesReturnItems.salesReturnId],
		references: [salesReturns.id]
	}),
}));

export const retainerInvoiceApplicationsRelations = relations(retainerInvoiceApplications, ({one}) => ({
	invoiceMaster: one(invoiceMaster, {
		fields: [retainerInvoiceApplications.invoiceId],
		references: [invoiceMaster.id]
	}),
	retainerInvoice: one(retainerInvoices, {
		fields: [retainerInvoiceApplications.retainerInvoiceId],
		references: [retainerInvoices.id]
	}),
}));

export const buyingRulesRelations = relations(buyingRules, ({many}) => ({
	products: many(products),
}));

export const productTypesRelations = relations(productTypes, ({many}) => ({
	products: many(products),
}));

export const racksRelations = relations(racks, ({many}) => ({
	products: many(products),
}));

export const storageConditionsRelations = relations(storageConditions, ({many}) => ({
	products: many(products),
}));

export const productPackSizesRelations = relations(productPackSizes, ({many}) => ({
	products: many(products),
}));

export const paymentMadeTaxRelations = relations(paymentMadeTax, ({one}) => ({
	paymentMadeMaster: one(paymentMadeMaster, {
		fields: [paymentMadeTax.paymentMadeId],
		references: [paymentMadeMaster.id]
	}),
	tdsRate: one(tdsRates, {
		fields: [paymentMadeTax.tdsTaxId],
		references: [tdsRates.id]
	}),
}));

export const inventoryStockCountRelations = relations(inventoryStockCount, ({one}) => ({
	user: one(users, {
		fields: [inventoryStockCount.assignTo],
		references: [users.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryStockCount.entityId],
		references: [organisationBranchMaster.id]
	}),
	warehouse_warehouse: one(warehouses, {
		fields: [inventoryStockCount.warehouse],
		references: [warehouses.id],
		relationName: "inventoryStockCount_warehouse_warehouses_id"
	}),
	warehouse_warehouseId: one(warehouses, {
		fields: [inventoryStockCount.warehouseId],
		references: [warehouses.id],
		relationName: "inventoryStockCount_warehouseId_warehouses_id"
	}),
}));

export const deliveryChallansRelations = relations(deliveryChallans, ({one, many}) => ({
	customer: one(customers, {
		fields: [deliveryChallans.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [deliveryChallans.entityId],
		references: [organisationBranchMaster.id]
	}),
	priceList: one(priceLists, {
		fields: [deliveryChallans.priceListId],
		references: [priceLists.id]
	}),
	warehouse: one(warehouses, {
		fields: [deliveryChallans.warehouseId],
		references: [warehouses.id]
	}),
	deliveryChallanAttachments: many(deliveryChallanAttachments),
	deliveryChallanDocumentLinks: many(deliveryChallanDocumentLinks),
	deliveryChallanItems: many(deliveryChallanItems),
}));

export const deliveryChallanAttachmentsRelations = relations(deliveryChallanAttachments, ({one}) => ({
	deliveryChallan: one(deliveryChallans, {
		fields: [deliveryChallanAttachments.deliveryChallanId],
		references: [deliveryChallans.id]
	}),
	user: one(users, {
		fields: [deliveryChallanAttachments.uploadedBy],
		references: [users.id]
	}),
}));

export const deliveryChallanDocumentLinksRelations = relations(deliveryChallanDocumentLinks, ({one}) => ({
	deliveryChallan: one(deliveryChallans, {
		fields: [deliveryChallanDocumentLinks.deliveryChallanId],
		references: [deliveryChallans.id]
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

export const reminderRulesRelations = relations(reminderRules, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [reminderRules.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const paymentMadeBillAllocationsRelations = relations(paymentMadeBillAllocations, ({one}) => ({
	bill: one(bills, {
		fields: [paymentMadeBillAllocations.billId],
		references: [bills.id]
	}),
	paymentMadeMaster: one(paymentMadeMaster, {
		fields: [paymentMadeBillAllocations.paymentMadeId],
		references: [paymentMadeMaster.id]
	}),
}));

export const deliveryChallanItemsRelations = relations(deliveryChallanItems, ({one, many}) => ({
	account: one(accounts, {
		fields: [deliveryChallanItems.accountId],
		references: [accounts.id]
	}),
	deliveryChallan: one(deliveryChallans, {
		fields: [deliveryChallanItems.deliveryChallanId],
		references: [deliveryChallans.id]
	}),
	product: one(products, {
		fields: [deliveryChallanItems.productId],
		references: [products.id]
	}),
	taxRate: one(taxRates, {
		fields: [deliveryChallanItems.taxId],
		references: [taxRates.id]
	}),
	deliveryChallanItemBatches: many(deliveryChallanItemBatches),
}));

export const inventoryRecurringStockCountRelations = relations(inventoryRecurringStockCount, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [inventoryRecurringStockCount.entityId],
		references: [organisationBranchMaster.id]
	}),
	warehouse: one(warehouses, {
		fields: [inventoryRecurringStockCount.warehouse],
		references: [warehouses.id]
	}),
}));

export const deliveryChallanItemBatchesRelations = relations(deliveryChallanItemBatches, ({one}) => ({
	batchMaster: one(batchMaster, {
		fields: [deliveryChallanItemBatches.batchId],
		references: [batchMaster.id]
	}),
	binMaster: one(binMaster, {
		fields: [deliveryChallanItemBatches.binId],
		references: [binMaster.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [deliveryChallanItemBatches.entityId],
		references: [organisationBranchMaster.id]
	}),
	deliveryChallanItem: one(deliveryChallanItems, {
		fields: [deliveryChallanItemBatches.deliveryChallanItemId],
		references: [deliveryChallanItems.id]
	}),
	batchStockLayer: one(batchStockLayers, {
		fields: [deliveryChallanItemBatches.layerId],
		references: [batchStockLayers.id]
	}),
	warehouse: one(warehouses, {
		fields: [deliveryChallanItemBatches.warehouseId],
		references: [warehouses.id]
	}),
}));

export const purchaseRequestApprovalRelations = relations(purchaseRequestApproval, ({one}) => ({
	user: one(users, {
		fields: [purchaseRequestApproval.approverId],
		references: [users.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [purchaseRequestApproval.entityId],
		references: [organisationBranchMaster.id]
	}),
	purchaseRequest: one(purchaseRequests, {
		fields: [purchaseRequestApproval.purchaseRequestId],
		references: [purchaseRequests.id]
	}),
}));

export const purchaseReturnItemsRelations = relations(purchaseReturnItems, ({one, many}) => ({
	purchaseReturn: one(purchaseReturns, {
		fields: [purchaseReturnItems.purchaseReturnId],
		references: [purchaseReturns.id]
	}),
	purchaseReturnItemBatches: many(purchaseReturnItemBatches),
}));

export const vendorAdvanceAllocationsRelations = relations(vendorAdvanceAllocations, ({one}) => ({
	bill: one(bills, {
		fields: [vendorAdvanceAllocations.billId],
		references: [bills.id]
	}),
	paymentMadeMaster: one(paymentMadeMaster, {
		fields: [vendorAdvanceAllocations.paymentMadeId],
		references: [paymentMadeMaster.id]
	}),
}));

export const printTemplatesRelations = relations(printTemplates, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [printTemplates.entityId],
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

export const purchaseReturnItemBatchesRelations = relations(purchaseReturnItemBatches, ({one}) => ({
	purchaseReturnItem: one(purchaseReturnItems, {
		fields: [purchaseReturnItemBatches.purchaseReturnItemId],
		references: [purchaseReturnItems.id]
	}),
	batchStockLayer: one(batchStockLayers, {
		fields: [purchaseReturnItemBatches.layerId],
		references: [batchStockLayers.id]
	}),
	batchMaster: one(batchMaster, {
		fields: [purchaseReturnItemBatches.batchId],
		references: [batchMaster.id]
	}),
}));

export const customerAddressesRelations = relations(customerAddresses, ({one}) => ({
	customer: one(customers, {
		fields: [customerAddresses.customerId],
		references: [customers.id]
	}),
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [customerAddresses.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const paymentMadeAttachmentsRelations = relations(paymentMadeAttachments, ({one}) => ({
	paymentMadeMaster: one(paymentMadeMaster, {
		fields: [paymentMadeAttachments.paymentMadeId],
		references: [paymentMadeMaster.id]
	}),
	user: one(users, {
		fields: [paymentMadeAttachments.uploadedBy],
		references: [users.id]
	}),
}));

export const emailNotificationTemplatesRelations = relations(emailNotificationTemplates, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [emailNotificationTemplates.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const customFieldsRelations = relations(customFields, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [customFields.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const approvalRulesRelations = relations(approvalRules, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [approvalRules.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const productVendorMappingsRelations = relations(productVendorMappings, ({one}) => ({
	product: one(products, {
		fields: [productVendorMappings.itemId],
		references: [products.id]
	}),
}));

export const defaultPaymentTermsRelations = relations(defaultPaymentTerms, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [defaultPaymentTerms.entityId],
		references: [organisationBranchMaster.id]
	}),
	paymentTerm: one(paymentTerms, {
		fields: [defaultPaymentTerms.paymentTermsId],
		references: [paymentTerms.id]
	}),
}));

export const recordLockingRelations = relations(recordLocking, ({one}) => ({
	organisationBranchMaster: one(organisationBranchMaster, {
		fields: [recordLocking.entityId],
		references: [organisationBranchMaster.id]
	}),
}));

export const vendorCreditsAttachmentsRelations = relations(vendorCreditsAttachments, ({one}) => ({
	vendorCredit: one(vendorCredits, {
		fields: [vendorCreditsAttachments.vendorCreditsId],
		references: [vendorCredits.id]
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