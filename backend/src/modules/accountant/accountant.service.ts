import {
  BadRequestException,
  ConflictException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { R2StorageService } from "./r2-storage.service";
import { db } from "../../db/db";
import {
  accountsManualJournals,
  accountsManualJournalItems,
  accountTransaction,
  accountsJournalNumberSettings,
  accountsJournalTemplates,
  accountsJournalTemplateItems,
  accountsRecurringJournals,
  accountsRecurringJournalItems,
  account,
  customer,
  vendor,
  transactionLocks,
} from "../../db/schema";
import { eq, and, ne, sql, desc, getTableColumns } from "drizzle-orm";

@Injectable()
export class AccountantService {
  private readonly defaultOrgId = "00000000-0000-0000-0000-000000000000";

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly r2StorageService: R2StorageService,
  ) {}

  async findAll(orgId?: string, outletId?: string) {
    const supabase = this.supabaseService.getClient();

    // 1. Fetch filtered active accounts
    let query = supabase.from("accounts").select("*").eq("is_deleted", false);

    if (orgId) query = query.eq("org_id", orgId);
    if (outletId) query = query.eq("outlet_id", outletId);

    const { data: accounts, error: accError } = await query.order(
      "user_account_name",
      { ascending: true },
    );

    if (accError) {
      console.error("Error fetching accounts:", accError);
      throw accError;
    }

    // 2. Fetch balances from transactions (Aggregated in memory for simplicity)
    let txQuery = supabase
      .from("account_transactions")
      .select("account_id, debit, credit");

    if (orgId) txQuery = txQuery.eq("org_id", orgId);
    if (outletId) txQuery = txQuery.eq("outlet_id", outletId);

    const { data: txs, error: balError } = await txQuery;

    if (balError) {
      console.warn(
        "Unable to fetch balances while listing accounts:",
        balError,
      );
    }

    const balanceMap = new Map<string, number>();
    const transactionCountMap = new Map<string, number>();
    if (txs) {
      txs.forEach((tx) => {
        const d = Number(tx.debit || 0);
        const c = Number(tx.credit || 0);
        const currentBal = balanceMap.get(tx.account_id) || 0;
        balanceMap.set(tx.account_id, currentBal + (d - c));

        const currentCount = transactionCountMap.get(tx.account_id) || 0;
        transactionCountMap.set(tx.account_id, currentCount + 1);
      });
    }

    // 3. Merge balances into account data
    const accountsWithBalances = accounts.map((acc) => {
      const bal = balanceMap.get(acc.id) || 0;
      return {
        ...acc,
        closing_balance: Math.abs(bal),
        closing_balance_type: bal >= 0 ? "Dr" : "Cr",
        transaction_count: transactionCountMap.get(acc.id) || 0,
      };
    });

    return this.buildTree(accountsWithBalances);
  }

  async findOne(id: string, orgId?: string) {
    const supabase = this.supabaseService.getClient();
    let query = supabase.from("accounts").select("*").eq("id", id);

    if (orgId) {
      query = query.eq("org_id", orgId);
    }

    const { data, error } = await query.single();

    if (error) throw error;

    // Fetch transaction count for findOne
    const { count, error: countError } = await supabase
      .from("account_transactions")
      .select("*", { count: "exact", head: true })
      .eq("account_id", id);

    const dto = this.mapToDto(data);
    dto.transactionCount = !countError ? count : 0;
    return dto;
  }

  async create(data: any) {
    const orgId = data.orgId || data.org_id || this.defaultOrgId;
    const outletId = data.outletId || data.outlet_id || null;

    // 🔄 Support both old (name/code), new (userAccountName), and snake_case keys
    data.userAccountName =
      data.userAccountName || data.name || data.user_account_name;
    data.systemAccountName = data.systemAccountName || data.system_account_name;
    data.accountCode = data.accountCode || data.code || data.account_code;
    data.parentId = data.parentId || data.parent_id;
    data.accountGroup = data.accountGroup || data.account_group;
    data.accountType = data.accountType || data.account_type;
    data.accountNumber = data.accountNumber || data.account_number;
    data.showInZerpaiExpense =
      data.showInZerpaiExpense ?? data.show_in_zerpai_expense;
    data.addToWatchlist = data.addToWatchlist ?? data.add_to_watchlist;

    if (data.userAccountName) {
      data.userAccountName = data.userAccountName.trim();
    }

    if (!data.userAccountName && !data.systemAccountName) {
      throw new ConflictException(
        "At least one account name (System or User) is required",
      );
    }

    // 🚔 Accounting Police: Group vs Type Validation (PRD Section 2)
    this.validateAccountGroupType(data.accountGroup, data.accountType);

    // 🌳 Parent Validation
    if (data.parentId) {
      await this.validateParent(data.parentId, data.accountGroup);
    }

    const supabase = this.supabaseService.getClient();
    const dbData = {
      ...this.mapToDb(data),
      org_id: orgId,
      outlet_id: outletId,
    };
    console.log("📤 Inserting into DB:", JSON.stringify(dbData, null, 2));

    const { data: created, error } = await supabase
      .from("accounts")
      .insert(dbData)
      .select()
      .single();

    if (error) {
      console.error("❌ Account Create Error:", error);
      if (error.code === "23505") {
        const detail = (error as any).detail || "";
        if (detail.includes("account_code")) {
          throw new ConflictException(
            "This account code has been associated with another account already. Please enter a unique account code.",
          );
        }
        throw new ConflictException(
          "Account with this name or code already exists",
        );
      }
      throw error;
    }

    console.log("✅ Account created successfully:", created.id);

    // ⚖️ Opening Balance Adjustment Logic (PRD Section 1)
    const openingBalance = Number(
      (data.openingBalance || data.opening_balance) ?? 0,
    );
    const openingBalanceType =
      data.openingBalanceType || data.opening_balance_type || "Dr";

    if (openingBalance > 0) {
      await this.handleOpeningBalanceAdjustment(
        created,
        openingBalance,
        openingBalanceType,
        orgId,
        outletId,
      );
    }

    return this.mapToDto(created);
  }

  private async handleOpeningBalanceAdjustment(
    account: any,
    openingBalance: number,
    openingBalanceType: string,
    orgId: string,
    outletId: string,
  ) {
    const supabase = this.supabaseService.getClient();
    console.log(
      `⚖️ Updating opening balance for account ${account.user_account_name || account.system_account_name}`,
    );

    try {
      // 1. Delete and Offsets (Idempotency)
      // We look for transactions of this account OR offset transactions referring to this account
      // Offset transactions have account_id = Adjustment Account AND description containing this account's name
      // This is still a bit brittle, but accurate enough for special "Opening Balance" type
      await supabase
        .from("account_transactions")
        .delete()
        .eq("account_id", account.id)
        .eq("transaction_type", "Opening Balance");

      // We also need to find and delete the offset in Opening Balance Adjustments
      // We'll search by type and a unique description pattern
      await supabase
        .from("account_transactions")
        .delete()
        .eq("transaction_type", "Opening Balance")
        .ilike(
          "description",
          `%Offset for opening balance of account ID: ${account.id}%`,
        );

      if (openingBalance === 0) return; // Just deleted, nothing to add

      const adjustmentAccountId =
        await this.ensureOpeningBalanceAdjustmentAccount(orgId, outletId);

      const transactions = [
        {
          org_id: orgId,
          outlet_id: outletId,
          account_id: account.id,
          transaction_date: new Date().toISOString(),
          transaction_type: "Opening Balance",
          debit: openingBalanceType === "Dr" ? openingBalance : 0,
          credit: openingBalanceType === "Cr" ? openingBalance : 0,
          description: "Opening Balance recorded during account creation/edit",
        },
        {
          org_id: orgId,
          outlet_id: outletId,
          account_id: adjustmentAccountId,
          transaction_date: new Date().toISOString(),
          transaction_type: "Opening Balance",
          debit: openingBalanceType === "Cr" ? openingBalance : 0,
          credit: openingBalanceType === "Dr" ? openingBalance : 0,
          description: `Offset for opening balance of account ID: ${account.id} (${account.user_account_name || account.system_account_name})`,
        },
      ];

      const { error: txError } = await supabase
        .from("account_transactions")
        .insert(transactions);

      if (txError) {
        console.error(
          "❌ Error creating opening balance transactions:",
          txError,
        );
      }
    } catch (err) {
      console.error("❌ Failed to handle opening balance adjustment:", err);
    }
  }

  async update(id: string, data: any) {
    const orgId = data.orgId || data.org_id;
    const outletId = data.outletId || data.outlet_id;
    // 🔄 Support both old (name/code), new (userAccountName), and snake_case keys
    data.userAccountName =
      data.userAccountName || data.name || data.user_account_name;
    data.systemAccountName = data.systemAccountName || data.system_account_name;
    data.accountCode = data.accountCode || data.code || data.account_code;
    data.parentId = data.parentId || data.parent_id;
    data.accountGroup = data.accountGroup || data.account_group;
    data.accountType = data.accountType || data.account_type;
    data.accountNumber = data.accountNumber || data.account_number;
    data.showInZerpaiExpense =
      data.showInZerpaiExpense ?? data.show_in_zerpai_expense;
    data.addToWatchlist = data.addToWatchlist ?? data.add_to_watchlist;

    if (data.userAccountName) {
      data.userAccountName = data.userAccountName.trim();
    }

    // 🚔 Accounting Police: Validate if group or type changed
    if (data.accountGroup || data.accountType) {
      const current = await this.findOne(id);
      this.validateAccountGroupType(
        data.accountGroup || current.accountGroup,
        data.accountType || current.accountType,
      );

      if (data.parentId) {
        await this.validateParent(
          data.parentId,
          data.accountGroup || current.accountGroup,
        );
      }
    }

    const supabase = this.supabaseService.getClient();
    const updateData = this.mapToDb(data);
    if (orgId) (updateData as any).org_id = orgId;
    if (outletId !== undefined) (updateData as any).outlet_id = outletId;

    const { data: updated, error } = await supabase
      .from("accounts")
      .update({
        ...updateData,
        modified_at: new Date().toISOString(),
      })
      .eq("id", id)
      .select()
      .single();

    if (error) {
      console.error("❌ Account Update Error:", error);
      if (error.code === "23505") {
        const detail = (error as any).detail || "";
        if (detail.includes("account_code")) {
          throw new ConflictException(
            "This account code has been associated with another account already. Please enter a unique account code.",
          );
        }
        throw new ConflictException(
          "Account with this name or code already exists",
        );
      }
      throw error;
    }

    // ⚖️ Opening Balance Adjustment Logic in Update (PRD Section 1)
    const openingBalance = Number(
      (data.openingBalance || data.opening_balance) ?? -1,
    );
    if (openingBalance >= 0) {
      const openingBalanceType =
        data.openingBalanceType || data.opening_balance_type || "Dr";

      // Only allow if transactions are 0 (excluding the opening balance we might be replacing)
      // Check current transaction count excluding Opening Balance
      const { count } = await supabase
        .from("account_transactions")
        .select("*", { count: "exact", head: true })
        .eq("account_id", id)
        .neq("transaction_type", "Opening Balance");

      if ((count || 0) === 0) {
        await this.handleOpeningBalanceAdjustment(
          updated,
          openingBalance,
          openingBalanceType,
          orgId || updated.org_id,
          outletId || updated.outlet_id,
        );
      }
    }

    return this.mapToDto(updated);
  }

  async remove(id: string, orgId?: string) {
    const supabase = this.supabaseService.getClient();

    // 🛡️ Deletion Protection (PRD Section 1)
    const journal = await this.findOne(id, orgId);

    if (journal.isDeletable === false || journal.isSystem === true) {
      throw new ConflictException(
        `Account "${journal.userAccountName || journal.systemAccountName}" is protected and cannot be deleted. Suggest setting it to inactive instead.`,
      );
    }

    // 1. Validation: Prevent deleting if in use
    const usage = await this.checkUsage(id);
    if (usage.inUse) {
      throw new ConflictException(`Cannot delete account: ${usage.reason}`);
    }

    let query = supabase
      .from("accounts")
      .update({
        is_deleted: true,
        is_active: false,
        modified_at: new Date().toISOString(),
      })
      .eq("id", id);

    if (orgId) {
      query = query.eq("org_id", orgId);
    }

    const { error } = await query;
    if (error) throw error;
    return true;
  }

  private validateAccountGroupType(group: string, type: string) {
    const assetTypes = [
      "Bank",
      "Cash",
      "Accounts Receivable",
      "Stock",
      "Payment Clearing Account",
      "Other Current Asset",
      "Fixed Asset",
      "Non Current Asset",
      "Intangible Asset",
      "Deferred Tax Asset",
      "Other Asset",
    ];
    const liabilityTypes = [
      "Credit Card",
      "Accounts Payable",
      "Other Current Liability",
      "Overseas Tax Payable",
      "Non Current Liability",
      "Deferred Tax Liability",
      "Other Liability",
      "Mortgages",
      "Construction Loans",
      "Home Equity Loans",
    ];
    const equityTypes = ["Equity"];
    const incomeTypes = ["Income", "Other Income"];
    const expenseTypes = ["Cost Of Goods Sold", "Expense", "Other Expense"];

    let valid = false;
    switch (group) {
      case "Assets":
        valid = assetTypes.includes(type);
        break;
      case "Liabilities":
        valid = liabilityTypes.includes(type);
        break;
      case "Equity":
        valid = equityTypes.includes(type);
        break;
      case "Income":
        valid = incomeTypes.includes(type);
        break;
      case "Expenses":
        valid = expenseTypes.includes(type);
        break;
    }

    if (!valid) {
      throw new ConflictException(
        `Invalid Accounting: Account type "${type}" is not allowed for group "${group}"`,
      );
    }
  }

  private async validateParent(parentId: string, currentGroup: string) {
    const parent = await this.findOne(parentId);
    if (parent.accountGroup !== currentGroup) {
      throw new ConflictException(
        `Invalid Hierarchy: Sub-account must belong to the same group as its parent ("${parent.accountGroup}")`,
      );
    }

    // 🚔 GST/Tax Account Parent Restriction (PRD Section 2)
    const restrictedTaxTypes = [
      "Overseas Tax Payable",
      "Deferred Tax Asset",
      "Deferred Tax Liability",
    ];
    if (restrictedTaxTypes.includes(parent.accountType)) {
      throw new ConflictException(
        `Invalid Hierarchy: Tax-related accounts ("${parent.accountType}") cannot be used as parent accounts.`,
      );
    }
  }

  private async ensureOpeningBalanceAdjustmentAccount(
    orgId: string,
    outletId?: string,
  ) {
    const supabase = this.supabaseService.getClient();
    const name = "Opening Balance Adjustments";

    // 1. Check if exists
    const { data: existing } = await supabase
      .from("accounts")
      .select("id")
      .eq("org_id", orgId)
      .eq("system_account_name", name)
      .maybeSingle();

    if (existing) return existing.id;

    // 2. Create it if missing (System Equity Account)
    console.log(`🔨 Creating system account: ${name}`);
    const { data: created, error: createError } = await supabase
      .from("accounts")
      .insert({
        org_id: orgId,
        outlet_id: outletId,
        system_account_name: name,
        user_account_name: name,
        account_group: "Equity",
        account_type: "Equity",
        is_system: true,
        is_deletable: false,
        is_active: true,
      })
      .select("id")
      .single();

    if (createError) {
      console.error("❌ Failed to create adjustment account:", createError);
      throw createError;
    }
    return created.id;
  }

  private async checkUsage(
    id: string,
  ): Promise<{ inUse: boolean; reason?: string }> {
    const supabase = this.supabaseService.getClient();

    try {
      // 1. Check for child accounts
      const { data: children, error: childError } = await supabase
        .from("accounts")
        .select("id")
        .eq("parent_id", id)
        .eq("is_deleted", false)
        .limit(1);

      if (childError) {
        (childError as any).table = "accounts (children)";
        throw childError;
      }
      if (children && children.length > 0) {
        return { inUse: true, reason: "This account has sub-accounts" };
      }

      // 2. Check for transactions
      const { data: txs, error: txError } = await supabase
        .from("account_transactions")
        .select("id")
        .eq("account_id", id)
        .limit(1);

      if (txError) {
        (txError as any).table = "account_transactions";
        throw txError;
      }
      if (txs && txs.length > 0) {
        return {
          inUse: true,
          reason: "This account has existing transactions",
        };
      }

      // 3. Check for product associations
      const { data: products, error: prodError } = await supabase
        .from("products")
        .select("id, product_name")
        .or(
          `sales_account_id.eq.${id},purchase_account_id.eq.${id},inventory_account_id.eq.${id}`,
        )
        .limit(1);

      if (prodError) {
        (prodError as any).table = "products";
        throw prodError;
      }
      if (products && products.length > 0) {
        return {
          inUse: true,
          reason: `This account is linked to product: ${products[0].product_name}`,
        };
      }

      return { inUse: false };
    } catch (e: any) {
      const tableName =
        e.table || e.message?.match(/table "([^"]+)"/)?.[1] || "unknown";
      console.error(`❌ Error in checkUsage (Table: ${tableName}):`, e);

      if (e.code === "42501") {
        throw new Error(
          `Permission denied for table "${tableName}" in checkUsage. Please run the GRANT ALL script in Supabase.`,
        );
      }
      throw e;
    }
  }

  async checkAccountJournalUsage(
    accountId: string,
    orgId?: string,
  ): Promise<{ hasJournalEntries: boolean }> {
    const rows = await db
      .select({ id: accountsManualJournalItems.id })
      .from(accountsManualJournalItems)
      .innerJoin(
        accountsManualJournals,
        eq(
          accountsManualJournalItems.manualJournalId,
          accountsManualJournals.id,
        ),
      )
      .where(
        and(
          eq(accountsManualJournalItems.accountId, accountId),
          eq(accountsManualJournals.isDeleted, false),
          orgId ? eq(accountsManualJournals.orgId, orgId) : undefined,
        ),
      )
      .limit(1);

    return { hasJournalEntries: rows.length > 0 };
  }

  async findByGroup(group: string, orgId?: string, outletId?: string) {
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("accounts")
      .select("*")
      .eq("account_group", group)
      .eq("is_deleted", false);

    if (orgId) query = query.eq("org_id", orgId);
    if (outletId) query = query.eq("outlet_id", outletId);

    const { data, error } = await query;

    if (error) throw error;
    return data.map((acc) => this.mapToDto(acc));
  }

  async findMetadata() {
    return {
      groupToTypes: {
        Assets: [
          "Bank",
          "Cash",
          "Accounts Receivable",
          "Stock",
          "Payment Clearing Account",
          "Other Current Asset",
          "Fixed Asset",
          "Non Current Asset",
          "Intangible Asset",
          "Deferred Tax Asset",
          "Other Asset",
        ],
        Liabilities: [
          "Credit Card",
          "Accounts Payable",
          "Other Current Liability",
          "Overseas Tax Payable",
          "Non Current Liability",
          "Deferred Tax Liability",
          "Other Liability",
        ],
        Expenses: [
          "Cost Of Goods Sold",
          "Expense",
          "Other Expense",
          "Contract Assets",
        ],
        Income: ["Income", "Other Income"],
        Equity: ["Equity"],
      },
      categoryDefinitions: {
        Assets:
          "Any short term/long term asset that can be converted into cash easily.",
        Liabilities:
          "Obligations arising from past transactions or future tax payments.",
        Expenses:
          "Direct costs attributable to production or costs for running normal business operations.",
        Income:
          "Revenue earned from normal business activities or secondary activities like interest.",
        Equity:
          "Owners or stakeholders interest on the assets of the business after deducting all the liabilities.",
      },
      typeDefinitions: {
        "Credit Card":
          "Create a trail of all your credit card transactions by creating a credit card account",
        "Account Name":
          "A descriptive name for this account. System accounts cannot be renamed.",
        "Account Type":
          "The classification of this account (e.g. Bank, Expense). System accounts are locked to their type.",
        Bank: "Track money and transactions in your bank accounts, such as checking, savings or money market accounts.",
        Cash: "Track the money you have on hand in your cash drawers or petty cash.",
        Equity:
          "Owners or stakeholders interest on the assets of the business after deducting all the liabilities.",
        Income: "Revenue earned from normal business activities.",
        Expense: "Costs incurred in the process of generating revenue.",
      },
      typeExamples: {
        Stock: ["Inventory assets"],
        "Accounts Receivable": ["Unpaid Invoices"],
        "Fixed Asset": [
          "Land and Buildings",
          "Plant, Machinery and Equipment",
          "Computers",
          "Furniture",
        ],
        Bank: ["Savings", "Checking", "Money Market accounts"],
        Cash: ["Petty cash", "Undeposited funds"],
        "Other Current Asset": ["Prepaid expenses", "Stocks and Mutual Funds"],
        "Other Asset": ["Goodwill", "Other intangible assets"],
        "Other Expense": ["Insurance", "Contribution towards charity"],
        "Cost Of Goods Sold": [
          "Material and Labor costs",
          "Cost of obtaining raw materials",
        ],
        Expense: [
          "Advertisements and Marketing",
          "Business Travel Expenses",
          "License Fees",
          "Utility Expenses",
        ],
        "Other Income": ["Interest Earned", "Dividend Earned"],
        Income: ["Sale of goods", "Services to customers"],
        Equity: ["Owner's Capital", "Shareholder investment"],
        "Deferred Tax Liability": [
          "Accelerated depreciation",
          "Revenue received in advance",
        ],
        "Overseas Tax Payable": [
          "Taxes for digital services to foreign customers",
        ],
        "Accounts Payable": ["Money owed to suppliers"],
        "Other Liability": ["Tax to be paid", "Loan to be Repaid"],
        "Non Current Liability": [
          "Notes Payable",
          "Debentures",
          "Long Term Loans",
        ],
        "Other Current Liability": ["Customer Deposits", "Tax Payable"],
        "Deferred Tax Asset": [
          "Warranty expenses",
          "Bad debt provisions",
          "Tax loss carry-forwards",
        ],
        "Payment Clearing Account": ["Stripe", "PayPal"],
        "Intangible Asset": ["Goodwill", "Patents", "Copyrights", "Trademarks"],
        "Non Current Asset": ["Long term investments"],
      },
      zerpaiExpenseSupportedTypes: [
        "Stock",
        "Fixed Asset",
        "Bank",
        "Cash",
        "Other Current Asset",
        "Other Asset",
        "Other Expense",
        "Contract Assets",
        "Cost Of Goods Sold",
        "Expense",
        "Other Liability",
        "Non Current Liability",
        "Credit Card",
        "Other Current Liability",
        "Intangible Asset",
      ],
      parentTypeRelationships: {},
      // Account types for which the "Make as sub-account" toggle is hidden in CREATE mode.
      // Rule source: business rule table column "Make As Sub Account = Not Possible".
      // Note: Accounts Payable, Accounts Receivable, and GST components (Output/Input
      // CGST/IGST/SGST) are NOT in this list — they are sub-accountable per the table.
      // GST components still appear in systemLockedParents (parent is fixed, not forbidden).
      nonSubAccountableTypes: [
        // Asset types
        "Bank",
        "Payment Clearing Account",
        "Deferred Tax Asset",
        "Inventory Asset",
        // Liability types
        "Overseas Tax Payable",
        "Deferred Tax Liability",
        "Tax Payable",
        "Unearned Revenue",
        "Opening Balance Adjustments",
        // Equity / special system names
        "Retained Earnings",
        "GST Payable",
        // Credit Card (own currency account, must be top-level)
        "Credit Card",
        // Expense / income leaf types
        "Bad Debt",
        "Bank Fees and Charges",
        "Purchase Discounts",
        "Salaries and Employee Wages",
        "Uncategorized",
        "Late Fee Income",
        "Reverse Charge Tax Input but not due",
        "Exchange Gain or Loss",
        "Dimension Adjustments",
        "Shipping Charge",
      ],
      // System account names whose parent account is immutable (cannot be re-parented).
      systemLockedParents: [
        "Output CGST",
        "Output IGST",
        "Output SGST",
        "Input CGST",
        "Input IGST",
        "Input SGST",
      ],
      // Account types that are never eligible to appear as a parent in the dropdown.
      restrictedParentTypes: [
        "Overseas Tax Payable",
        "Deferred Tax Asset",
        "Deferred Tax Liability",
      ],
    };
  }

  async getTransactions(
    accountId: string,
    limit: any = 10,
    orgId?: string,
    outletId?: string,
  ) {
    const limitNum = typeof limit === "string" ? parseInt(limit, 10) : limit;
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("account_transactions")
      .select(
        `
        *,
        account:accounts(user_account_name, system_account_name)
      `,
      )
      .eq("account_id", accountId)
      .order("transaction_date", { ascending: false })
      .limit(limitNum || 10);

    if (orgId) {
      query = query.eq("org_id", orgId);
    }
    if (outletId) {
      query = query.eq("outlet_id", outletId);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data.map((t) => ({
      ...t,
      account_name:
        t.account?.user_account_name || t.account?.system_account_name || "",
    }));
  }

  async searchTransactions(filters: {
    accountId?: string;
    startDate?: string;
    endDate?: string;
    minAmount?: number;
    maxAmount?: number;
    limit?: number;
    orgId?: string;
    outletId?: string;
  }) {
    const supabase = this.supabaseService.getClient();
    let query = supabase.from("account_transactions").select(`
      *,
      account:accounts(id, user_account_name, system_account_name)
    `);

    if (filters.accountId) {
      query = query.eq("account_id", filters.accountId);
    }
    if (filters.startDate) {
      query = query.gte("transaction_date", filters.startDate);
    }
    if (filters.endDate) {
      query = query.lte("transaction_date", filters.endDate);
    }
    if (filters.orgId) {
      query = query.eq("org_id", filters.orgId);
    }
    if (filters.outletId) {
      query = query.eq("outlet_id", filters.outletId);
    }
    if (filters.minAmount) {
      query = query.or(
        `debit.gte.${filters.minAmount},credit.gte.${filters.minAmount}`,
      );
    }
    if (filters.maxAmount) {
      query = query.or(
        `debit.lte.${filters.maxAmount},credit.lte.${filters.maxAmount}`,
      );
    }

    const limitNum =
      typeof filters.limit === "string"
        ? parseInt(filters.limit, 10)
        : filters.limit;

    const { data, error } = await query
      .order("transaction_date", { ascending: false })
      .limit(limitNum || 100);

    if (error) throw error;
    return data.map((t) => ({
      ...t,
      account_name:
        t.account?.user_account_name || t.account?.system_account_name || "",
    }));
  }

  async bulkUpdateTransactions(
    transactionIds: string[],
    targetAccountId: string,
  ) {
    const supabase = this.supabaseService.getClient();

    const { data, error } = await supabase
      .from("account_transactions")
      .update({ account_id: targetAccountId })
      .in("id", transactionIds)
      .select();

    if (error) throw error;
    return data;
  }

  async getClosingBalance(
    accountId: string,
    orgId?: string,
    outletId?: string,
  ) {
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("account_transactions")
      .select("debit, credit")
      .eq("account_id", accountId);

    if (orgId) query = query.eq("org_id", orgId);
    if (outletId) query = query.eq("outlet_id", outletId);

    const { data, error } = await query;

    if (error) throw error;

    let balance = 0;
    data.forEach((tx) => {
      const debit = parseFloat(tx.debit || "0");
      const credit = parseFloat(tx.credit || "0");
      balance += debit - credit;
    });

    return {
      balance: Math.abs(balance),
      type: balance >= 0 ? "Dr" : "Cr",
    };
  }

  async search(query: string, orgId?: string, outletId?: string) {
    const supabase = this.supabaseService.getClient();
    let q = supabase
      .from("accounts")
      .select("*")
      .eq("is_deleted", false)
      .or(`user_account_name.ilike.%${query}%,account_code.ilike.%${query}%`);

    if (orgId) q = q.eq("org_id", orgId);
    if (outletId) q = q.eq("outlet_id", outletId);

    const { data, error } = await q;

    if (error) throw error;
    return data.map((acc) => this.mapToDto(acc));
  }

  private buildTree(accounts: any[]) {
    const map = new Map();
    const roots = [];

    // Map all accounts to a DTO structure
    accounts.forEach((acc) => {
      map.set(acc.id, this.mapToDto(acc));
    });

    // Link children to parents
    map.forEach((node) => {
      if (node.parentId && map.has(node.parentId)) {
        const parent = map.get(node.parentId);
        node.parentName = parent.name;
        parent.children.push(node);
      } else {
        roots.push(node);
      }
    });

    return roots;
  }

  async saveOpeningBalances(data: {
    debits: Record<string, number>;
    credits: Record<string, number>;
    openingDate: string;
  }) {
    const supabase = this.supabaseService.getClient();
    const { debits, credits, openingDate } = data;

    console.log("Saving opening balances for date:", openingDate);

    // 1. Delete old opening balance transactions to ensure idempotency
    const { error: deleteError } = await supabase
      .from("account_transactions")
      .delete()
      .eq("transaction_type", "Opening Balance");

    if (deleteError) {
      console.error("Error deleting old opening balances:", deleteError);
      throw deleteError;
    }

    // 2. Prepare new transactions
    const txs = [];
    const allAccountIds = new Set([
      ...Object.keys(debits),
      ...Object.keys(credits),
    ]);

    for (const id of allAccountIds) {
      const debit = debits[id] || 0;
      const credit = credits[id] || 0;

      if (debit === 0 && credit === 0) continue;

      txs.push({
        account_id: id,
        transaction_date: openingDate,
        transaction_type: "Opening Balance",
        debit,
        credit,
        description: "Opening Balance recorded via Opening Balances screen",
      });
    }

    if (txs.length > 0) {
      const { error: insertError } = await supabase
        .from("account_transactions")
        .insert(txs);

      if (insertError) {
        console.error("Error inserting opening balances:", insertError);
        throw insertError;
      }
    }

    return { success: true, count: txs.length };
  }

  private mapToDb(dto: any) {
    const db: any = {};

    if (dto.systemAccountName !== undefined)
      db.system_account_name = dto.systemAccountName;
    if (dto.userAccountName !== undefined || dto.name !== undefined)
      db.user_account_name = dto.userAccountName || dto.name;
    if (dto.accountCode !== undefined || dto.code !== undefined)
      db.account_code = dto.accountCode || dto.code;
    if (dto.description !== undefined) db.description = dto.description;
    if (dto.accountNumber !== undefined) db.account_number = dto.accountNumber;
    if (dto.ifsc !== undefined) db.ifsc = dto.ifsc;
    if (dto.currency !== undefined) db.currency = dto.currency;
    if (dto.showInZerpaiExpense !== undefined)
      db.show_in_zerpai_expense = dto.showInZerpaiExpense;
    if (dto.addToWatchlist !== undefined)
      db.add_to_watchlist = dto.addToWatchlist;
    if (dto.accountGroup !== undefined) db.account_group = dto.accountGroup;
    if (dto.accountType !== undefined) db.account_type = dto.accountType;
    if (dto.parentId !== undefined) db.parent_id = dto.parentId || null;
    if (dto.isSystem !== undefined) db.is_system = dto.isSystem;
    if (dto.isActive !== undefined) db.is_active = dto.isActive;
    if (dto.isDeletable !== undefined) db.is_deletable = dto.isDeletable;
    if (dto.createdBy !== undefined) db.created_by = dto.createdBy;
    if (dto.modifiedBy !== undefined) db.modified_by = dto.modifiedBy;

    return db;
  }

  private mapToDto(acc: any) {
    const rawSystemName = acc.system_account_name;
    const rawUserName = acc.user_account_name;

    // Display name logic: User name has priority, fallback to System name
    const displayName =
      rawUserName && rawUserName.trim().length > 0
        ? rawUserName
        : rawSystemName || "Unnamed Account";

    return {
      id: acc.id,
      systemAccountName: rawSystemName,
      userAccountName: rawUserName,
      name: displayName, // Support both for legacy frontend compatibility
      code: acc.account_code,
      description: acc.description,
      accountNumber: acc.account_number,
      ifsc: acc.ifsc,
      currency: acc.currency,
      showInZerpaiExpense: acc.show_in_zerpai_expense,
      addToWatchlist: acc.add_to_watchlist,
      accountGroup: acc.account_group,
      accountType: acc.account_type,
      parentId: acc.parent_id,
      parentName: null,
      orgId: acc.org_id,
      outletId: acc.outlet_id,
      isSystem: acc.is_system,
      isDeletable: acc.is_deletable,
      isActive: acc.is_active,
      isDeleted: acc.is_deleted,
      transactionCount: acc.transaction_count || 0,
      modifiedAt: acc.modified_at,
      modifiedBy: acc.modified_by,
      children: [],
      balance: acc.closing_balance || 0,
      balanceType: acc.closing_balance_type || "Dr",
    };
  }

  // --- Manual Journals Methods ---

  async findManualJournals(orgId?: string) {
    try {
      // Use Drizzle to handle polymorphic joins (customers/vendors)
      const rows = await db
        .select({
          journal: getTableColumns(accountsManualJournals),
          item: getTableColumns(accountsManualJournalItems),
          account: {
            id: account.id,
            userAccountName: account.userAccountName,
            systemAccountName: account.systemAccountName,
          },
          customerName: customer.displayName,
          vendorName: vendor.displayName,
        })
        .from(accountsManualJournals)
        .innerJoin(
          accountsManualJournalItems,
          eq(
            accountsManualJournals.id,
            accountsManualJournalItems.manualJournalId,
          ),
        )
        .leftJoin(account, eq(accountsManualJournalItems.accountId, account.id))
        .leftJoin(
          customer,
          and(
            eq(accountsManualJournalItems.contactId, customer.id),
            eq(accountsManualJournalItems.contactType, "customer"),
          ),
        )
        .leftJoin(
          vendor,
          and(
            eq(accountsManualJournalItems.contactId, vendor.id),
            eq(accountsManualJournalItems.contactType, "vendor"),
          ),
        )
        .where(
          and(
            orgId ? eq(accountsManualJournals.orgId, orgId) : undefined,
            eq(accountsManualJournals.isDeleted, false),
          ),
        )
        .orderBy(
          desc(accountsManualJournals.journalDate),
          desc(accountsManualJournals.createdAt),
        );

      // Group items by journal to match the nested JSON structure expected by Flutter
      const journalsMap = new Map<string, any>();
      for (const row of rows) {
        const jId = row.journal.id;
        if (!journalsMap.has(jId)) {
          journalsMap.set(jId, {
            ...row.journal,
            items: [],
          });
        }

        journalsMap.get(jId).items.push({
          ...row.item,
          account: row.account,
          contact_name:
            row.customerName || row.vendorName || row.item.contactName || "",
        });
      }

      return Array.from(journalsMap.values()).map((j) =>
        this.mapManualJournal(j),
      );
    } catch (error: any) {
      console.error("DEBUG Error in findManualJournals (Drizzle): ", error);
      throw new InternalServerErrorException(
        `Failed to fetch manual journals: ${error.message || error}`,
      );
    }
  }

  async findManualJournal(id: string, orgId?: string) {
    try {
      const rows = await db
        .select({
          journal: getTableColumns(accountsManualJournals),
          item: getTableColumns(accountsManualJournalItems),
          account: {
            id: account.id,
            userAccountName: account.userAccountName,
            systemAccountName: account.systemAccountName,
          },
          customerName: customer.displayName,
          vendorName: vendor.displayName,
        })
        .from(accountsManualJournals)
        .innerJoin(
          accountsManualJournalItems,
          eq(
            accountsManualJournals.id,
            accountsManualJournalItems.manualJournalId,
          ),
        )
        .leftJoin(account, eq(accountsManualJournalItems.accountId, account.id))
        .leftJoin(
          customer,
          and(
            eq(accountsManualJournalItems.contactId, customer.id),
            eq(accountsManualJournalItems.contactType, "customer"),
          ),
        )
        .leftJoin(
          vendor,
          and(
            eq(accountsManualJournalItems.contactId, vendor.id),
            eq(accountsManualJournalItems.contactType, "vendor"),
          ),
        )
        .where(
          and(
            eq(accountsManualJournals.id, id),
            orgId ? eq(accountsManualJournals.orgId, orgId) : undefined,
          ),
        );

      if (rows.length === 0) {
        throw new NotFoundException(`Manual journal "${id}" was not found.`);
      }

      // Reconstruct single journal with items
      const journal = {
        ...rows[0].journal,
        items: rows.map((row) => ({
          ...row.item,
          account: row.account,
          contact_name:
            row.customerName || row.vendorName || row.item.contactName || "",
        })),
      };

      return this.mapManualJournal(journal);
    } catch (error: any) {
      if (error instanceof NotFoundException) throw error;
      console.error("DEBUG Error in findManualJournal (Drizzle): ", error);
      throw new InternalServerErrorException(
        `Failed to fetch manual journal: ${error.message || error}`,
      );
    }
  }

  private mapDrizzleManualJournals(rows: any[]): any[] {
    const journalMap = new Map<string, any>();

    for (const row of rows) {
      if (!row || !row.journal || !row.journal.id) continue;
      const journalId = row.journal.id;

      if (!journalMap.has(journalId)) {
        journalMap.set(journalId, {
          ...row.journal,
          // Map camelCase to snake_case for frontend compatibility if missing
          journal_date: row.journal.journalDate,
          journal_number: row.journal.journalNumber,
          reference_number: row.journal.referenceNumber,
          fiscal_year_id: row.journal.fiscalYearId,
          is_13th_month_adjustment: row.journal.is13thMonthAdjustment,
          reporting_method: row.journal.reportingMethod,
          recurring_journal_id: row.journal.recurringJournalId,
          created_at: row.journal.createdAt,
          updated_at: row.journal.updatedAt,
          items: [],
        });
      }

      if (row.item && row.item.id) {
        journalMap.get(journalId).items.push({
          ...row.item,
          // Map item camelCase to snake_case
          manual_journal_id: row.item.manualJournalId,
          account_id: row.item.accountId,
          contact_id: row.item.contactId,
          contact_type: row.item.contactType,
          contact_name:
            row.customerName || row.vendorName || row.item.contactName,
          sort_order: row.item.sortOrder,
          created_at: row.item.createdAt,
          account: row.accountId
            ? {
                id: row.accountId,
                userAccountName: row.userAccountName,
                systemAccountName: row.systemAccountName,
              }
            : null,
        });
      }
    }

    return Array.from(journalMap.values());
  }

  async createManualJournal(dto: any, orgId?: string) {
    const { items, ...header } = dto;
    const normalizedItems = this.normalizeManualJournalItemsInput(items);
    const normalizedStatus = this.normalizeManualJournalStatus(
      header.status || header.journal_status,
    );
    const scope = this.parseSettingsScope(header);
    const settings = await this.findJournalNumberSettings(scope);
    const isDraftCreate = normalizedStatus === "draft";
    const isAutoGenerate = settings.auto_generate === true;
    const persistedItems = isDraftCreate
      ? this.getPersistableDraftItems(normalizedItems)
      : normalizedItems;
    const effectiveJournalDate = this.normalizeDateOnly(
      header.journalDate ||
        header.journal_date ||
        new Date().toISOString().slice(0, 10),
    );

    if (!isDraftCreate) {
      this.validateManualJournalItems(normalizedItems);
    }

    if (normalizedStatus === "posted") {
      await this.assertDateInActiveFiscalYear(effectiveJournalDate);
    }

    const requestedJournalNumber = (
      header.journalNumber ||
      header.journal_number ||
      ""
    )
      .toString()
      .trim();

    try {
      return await db.transaction(async (tx) => {
        let journalNumber = requestedJournalNumber;
        let nextNumberToPersist: number | null = null;
        const normalizedPrefix = this.normalizeJournalPrefix(settings.prefix);
        const nextSearchNumber = this.normalizeNextNumber(settings.next_number);

        if (isAutoGenerate) {
          const generated = await this.getNextAvailableJournalNumber(
            normalizedPrefix,
            nextSearchNumber,
          );
          journalNumber = generated.journalNumber;
          nextNumberToPersist = generated.nextNumberAfter;
        } else {
          if (!journalNumber) {
            throw new BadRequestException("Journal number is required.");
          }
          await this.ensureJournalNumberUnique(journalNumber);
        }

        // 2. Insert Header
        const journals = await tx
          .insert(accountsManualJournals)
          .values({
            orgId:
              orgId || this.normalizeUuid(scope.orgId) || this.defaultOrgId,
            outletId: this.normalizeUuid(scope.outletId),
            journalNumber: journalNumber,
            fiscalYearId: this.normalizeUuid(
              header.fiscalYearId || header.fiscal_year_id,
            ),
            referenceNumber:
              header.referenceNumber || header.reference_number || null,
            journalDate: effectiveJournalDate,
            notes: header.notes,
            is13thMonthAdjustment: header.is13thMonthAdjustment || false,
            reportingMethod: header.reportingMethod || "accrual_and_cash",
            currencyCode: header.currencyCode || header.currency_code || "INR",
            status: this.getDbStatusForCreate(normalizedStatus),
            totalAmount: (
              header.totalAmount ||
              header.total_amount ||
              this.calculateManualJournalTotal(persistedItems)
            ).toString(),
            recurringJournalId: this.normalizeUuid(
              header.recurring_journal_id || header.recurringJournalId,
            ),
            createdById: this.normalizeUuid(
              header.createdBy || header.created_by || scope.userId,
            ),
          })
          .returning();

        const journal = journals[0];
        if (!journal) throw new Error("Failed to create journal header");

        // 3. Insert Items
        const insertedItems = await this.replaceManualJournalItems(
          journal.id,
          persistedItems,
          tx,
        );

        // 4. Increment Journal Number if auto-generate is active
        if (isAutoGenerate && settings.id && nextNumberToPersist != null) {
          await tx
            .update(accountsJournalNumberSettings)
            .set({ nextNumber: nextNumberToPersist })
            .where(eq(accountsJournalNumberSettings.id, settings.id));
        }

        // 5. Post to transactions if requested
        if (normalizedStatus === "posted") {
          // Pass the already-inserted journal + items directly to avoid a
          // re-fetch via the regular db pool (which cannot see the uncommitted row).
          // Bridge both naming conventions since postJournalToTransactions uses snake_case
          // for some fields (journal_date, journal_number) while Drizzle returns camelCase.
          await this.postJournalToTransactions(journal.id, orgId, tx, {
            ...journal,
            journal_date: journal.journalDate,
            journal_number: journal.journalNumber,
            items: insertedItems,
          });
        }

        // 6. Return mapped data directly from transaction values
        return this.mapManualJournal({
          ...journal,
          items: insertedItems,
        });
      });
    } catch (error) {
      console.error("Full DB Error in createManualJournal:", error);
      throw error;
    }
  }

  async updateManualJournal(id: string, dto: any, orgId?: string) {
    await this.ensureDraftManualJournal(id, "updated", orgId);

    const { items, ...header } = dto;
    const hasItems = Array.isArray(items);
    const normalizedItems = hasItems
      ? this.normalizeManualJournalItemsInput(items)
      : [];
    const persistedItems = hasItems
      ? this.getPersistableDraftItems(normalizedItems)
      : [];

    const requestedStatus = header.status || header.journal_status;
    if (
      requestedStatus != null &&
      this.normalizeManualJournalStatus(requestedStatus) !== "draft"
    ) {
      throw new BadRequestException(
        "Use /manual-journals/:id/status to post or cancel journals.",
      );
    }

    const rawJournalNumber = header.journalNumber || header.journal_number;
    const journalNumber =
      rawJournalNumber == null ? null : rawJournalNumber.toString().trim();

    if (journalNumber != null) {
      if (!journalNumber) {
        throw new BadRequestException("Journal number cannot be empty.");
      }
      await this.ensureJournalNumberUnique(journalNumber, id);
    }

    const updatePayload: Record<string, any> = {};

    if (journalNumber != null) updatePayload.journalNumber = journalNumber;
    if ("fiscalYearId" in header || "fiscal_year_id" in header) {
      updatePayload.fiscalYearId =
        header.fiscalYearId || header.fiscal_year_id || null;
    }
    if ("referenceNumber" in header || "reference_number" in header) {
      updatePayload.referenceNumber =
        header.referenceNumber || header.reference_number || null;
    }
    if ("journalDate" in header || "journal_date" in header) {
      const rawDate = header.journalDate || header.journal_date;
      updatePayload.journalDate = rawDate
        ? this.normalizeDateOnly(rawDate)
        : null;
    }
    if ("notes" in header) updatePayload.notes = header.notes;
    if (
      "is13thMonthAdjustment" in header ||
      "is_13th_month_adjustment" in header
    ) {
      updatePayload.is13thMonthAdjustment =
        header.is13thMonthAdjustment ??
        header.is_13th_month_adjustment ??
        false;
    }
    if ("reportingMethod" in header || "reporting_method" in header) {
      updatePayload.reportingMethod =
        header.reportingMethod || header.reporting_method || "accrual_and_cash";
    }
    if (
      "currencyCode" in header ||
      "currency_code" in header ||
      "currency" in header
    ) {
      updatePayload.currencyCode =
        header.currencyCode || header.currency_code || header.currency || "INR";
    }
    if (hasItems) {
      updatePayload.totalAmount =
        this.calculateManualJournalTotal(persistedItems).toString();
    }

    updatePayload.updatedAt = new Date();

    try {
      return await db.transaction(async (tx) => {
        const whereClauses: any[] = [
          eq(accountsManualJournals.id, id),
          eq(accountsManualJournals.status, "draft"),
        ];

        if (orgId) {
          whereClauses.push(eq(accountsManualJournals.orgId, orgId));
        }

        const updatedHeaders = await tx
          .update(accountsManualJournals)
          .set(updatePayload)
          .where(and(...whereClauses))
          .returning();

        if (updatedHeaders.length === 0) {
          throw new BadRequestException(
            "Journal not found, not in draft status, or does not belong to your organization.",
          );
        }

        const finalHeader = updatedHeaders[0];
        let updatedItems = [];

        if (hasItems) {
          // Replace items
          await tx
            .delete(accountsManualJournalItems)
            .where(eq(accountsManualJournalItems.manualJournalId, id));

          if (persistedItems.length > 0) {
            const itemRows = persistedItems.map((item, index) => ({
              manualJournalId: id,
              accountId: item.accountId,
              description: item.description,
              contactId: item.contactId,
              contactType: item.contactType,
              debit: item.debit || "0",
              credit: item.credit || "0",
              sortOrder: index,
            }));
            const insertedItems = await tx
              .insert(accountsManualJournalItems)
              .values(itemRows)
              .returning();
            updatedItems = insertedItems;
          }
        } else {
          // Fetch existing items if not provided
          updatedItems = await tx
            .select()
            .from(accountsManualJournalItems)
            .where(eq(accountsManualJournalItems.manualJournalId, id))
            .orderBy(accountsManualJournalItems.sortOrder);
        }

        return this.mapManualJournal({
          ...finalHeader,
          items: updatedItems,
        });
      });
    } catch (error) {
      console.error("Error in updateManualJournal:", error);
      throw error;
    }
  }

  async deleteManualJournal(id: string, orgId?: string) {
    try {
      // 1. Fetch attachment keys for R2 cleanup
      const supabase = this.supabaseService.getClient();
      const { data: attachments } = await supabase
        .from("accounts_manual_journal_attachments")
        .select("file_path")
        .eq("manual_journal_id", id);

      // 2. Hard-delete the journal. Child items and attachment rows cascade.
      const whereClause: any[] = [eq(accountsManualJournals.id, id)];
      if (orgId) whereClause.push(eq(accountsManualJournals.orgId, orgId));

      await db
        .update(accountsManualJournals)
        .set({ isDeleted: true, updatedAt: new Date() })
        .where(and(...whereClause));

      // 3. Cleanup R2 attachment files (DB rows stay for audit).
      if (attachments && attachments.length > 0) {
        for (const att of attachments) {
          await this.r2StorageService.deleteFile(att.file_path);
        }
      }

      return { success: true };
    } catch (error) {
      console.error("Full DB Error in deleteManualJournal:", error);
      throw error;
    }
  }

  async cloneManualJournal(id: string, orgId?: string) {
    const original = await this.findManualJournal(id, orgId);
    const {
      id: _id,
      journal_number: _jn,
      created_at: _ca,
      status: _st,
      items: itemsRaw,
      orgId: originalOrgId,
      outletId: originalOutletId,
      ...header
    } = original;

    const cloneDto = {
      ...header,
      orgId: originalOrgId,
      outletId: originalOutletId,
      notes: `Clone of ${original.journal_number}${original.notes ? ": " + original.notes : ""}`,
      status: "draft",
      items: (itemsRaw || []).map((item) => ({
        accountId: item.account_id || item.accountId,
        description: item.description,
        contactId: item.contact_id || item.contactId,
        contactType: item.contact_type || item.contactType,
        debit: item.debit,
        credit: item.credit,
      })),
    };

    return this.createManualJournal(cloneDto, orgId);
  }

  async reverseManualJournal(id: string, orgId?: string) {
    const original = await this.findManualJournal(id, orgId);
    if (!original.journal_number) {
      throw new BadRequestException("Original journal has no number.");
    }
    const {
      id: _id,
      journal_number: _jn,
      created_at: _ca,
      status: _st,
      items: itemsRaw,
      orgId: originalOrgId,
      outletId: originalOutletId,
      ...header
    } = original;

    const reverseDto = {
      ...header,
      orgId: originalOrgId,
      outletId: originalOutletId,
      journal_number: `R-${original.journal_number}`,
      notes: `Reverse of ${original.journal_number}${original.notes ? ": " + original.notes : ""}`,
      status: "draft",
      items: (itemsRaw || []).map((item) => ({
        accountId: item.account_id || item.accountId,
        description: item.description,
        contactId: item.contact_id || item.contactId,
        contactType: item.contact_type || item.contactType,
        debit: item.credit, // SWAPPED
        credit: item.debit, // SWAPPED
      })),
    };

    return this.createManualJournal(reverseDto, orgId);
  }

  async createTemplateFromManualJournal(id: string, orgId?: string) {
    const journal = await this.findManualJournal(id, orgId);

    const templateDto = {
      orgId: journal.org_id || journal.orgId,
      outletId: journal.outlet_id || journal.outletId,
      templateName: `Template from ${journal.journal_number}`,
      referenceNumber: journal.reference_number,
      notes: journal.notes,
      reportingMethod: journal.reporting_method,
      currencyCode: journal.currency_code,
      items: (journal.items || []).map((item) => ({
        accountId: item.account_id || item.accountId,
        description: item.description,
        contactId: item.contact_id || item.contactId,
        contactType: item.contact_type || item.contactType,
        debit: item.debit,
        credit: item.credit,
      })),
    };

    return this.createJournalTemplate(templateDto);
  }

  async updateManualJournalStatus(id: string, status: string, orgId?: string) {
    const targetStatus = this.normalizeManualJournalStatus(status);
    const journal = await this.findManualJournal(id, orgId);

    if (journal.status !== "draft") {
      throw new ConflictException(
        "Only draft journals can be posted or cancelled.",
      );
    }

    try {
      if (targetStatus === "posted") {
        await this.assertDateInActiveFiscalYear(
          journal.journal_date || journal.journalDate,
        );
        this.validateManualJournalItems(journal.items || []);

        await db.transaction(async (tx) => {
          await this.postJournalToTransactions(id, orgId, tx);
          const updateWhere: any[] = [eq(accountsManualJournals.id, id)];
          if (orgId) {
            updateWhere.push(eq(accountsManualJournals.orgId, orgId));
          }
          await tx
            .update(accountsManualJournals)
            .set({ status: targetStatus })
            .where(and(...updateWhere));
        });
      } else if (targetStatus === "cancelled") {
        await db.transaction(async (tx) => {
          await this.clearManualJournalTransactions(id, orgId, tx);
          const updateWhere: any[] = [eq(accountsManualJournals.id, id)];
          if (orgId) {
            updateWhere.push(eq(accountsManualJournals.orgId, orgId));
          }
          await tx
            .update(accountsManualJournals)
            .set({ status: targetStatus })
            .where(and(...updateWhere));
        });
      } else {
        await this.setManualJournalStatus(id, targetStatus);
      }
      return this.findManualJournal(id, orgId);
    } catch (error) {
      console.error("Full DB Error in updateManualJournalStatus:", error);
      throw error;
    }
  }

  async postJournalToTransactions(
    journalId: string,
    orgId?: string,
    tx?: any,
    preloadedJournal?: any,
  ) {
    // When called from inside a db.transaction() the journal row is not yet committed
    // and findManualJournal (regular pool) would return 404. Use preloadedJournal instead.
    const journal =
      preloadedJournal ?? (await this.findManualJournal(journalId, orgId));
    if (!journal) throw new NotFoundException("Journal not found.");
    const dbClient = tx || db;
    const items = journal.items || [];

    this.validateManualJournalItems(items);
    await this.clearManualJournalTransactions(journalId, orgId, tx);

    // Audit Traceability: Determine if this is a manual entry or recurring generation
    const auditSourceType = "manual_journal";

    const transactions = items.map((item: any) => ({
      accountId: item.account_id || item.accountId,
      orgId: journal.org_id || journal.orgId || orgId || this.defaultOrgId,
      outletId: journal.outlet_id || journal.outletId || null,
      transactionDate: new Date(journal.journal_date || journal.journalDate),
      transactionType: "Manual Journal",
      referenceNumber: journal.journal_number || journal.journalNumber || null,
      description:
        item.contact_name || item.contactName
          ? `${item.contact_name || item.contactName} - ${item.description || journal.notes || ""}`
          : item.description || journal.notes,
      debit: this.toNumber(item.debit).toString(),
      credit: this.toNumber(item.credit).toString(),
      sourceId: journal.id,
      sourceType: auditSourceType,
      contactId: item.contact_id || item.contactId,
      contactType: item.contact_type || item.contactType,
    }));

    if (transactions.length > 0) {
      await dbClient.insert(accountTransaction).values(transactions);
    }
  }

  private async clearManualJournalTransactions(
    journalId: string,
    orgId?: string,
    tx?: any,
  ) {
    const dbClient = tx || db;
    const whereClause = [
      eq(accountTransaction.sourceId, journalId),
      eq(accountTransaction.sourceType, "manual_journal"),
    ];
    if (orgId) {
      whereClause.push(eq(accountTransaction.orgId, orgId));
    }
    await dbClient.delete(accountTransaction).where(and(...whereClause));
  }

  async findManualJournalAttachments(id: string, orgId?: string) {
    await this.findManualJournal(id, orgId);

    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("accounts_manual_journal_attachments")
      .select(
        "id, manual_journal_id, file_name, file_path, file_size, uploaded_at",
      )
      .eq("manual_journal_id", id);

    if (orgId) {
      query = query.eq("org_id", orgId);
    }

    const { data, error } = await query.order("uploaded_at", {
      ascending: false,
    });

    if (error) {
      this.throwFriendlySupabaseError(
        error,
        `Unable to fetch attachments for manual journal "${id}".`,
      );
    }

    // Secure Privacy: Generate Presigned URLs for each attachment
    const attachments = await Promise.all(
      (data || []).map(async (att) => {
        try {
          // file_path contains the R2 key
          const presignedUrl = await this.r2StorageService.getPresignedUrl(
            att.file_path,
          );
          return {
            ...att,
            public_url: presignedUrl, // Frontend will use this temporary URL
          };
        } catch (err) {
          console.error(`Failed to sign attachment ${att.id}`, err);
          return {
            ...att,
            public_url: null,
            error: "Failed to generate access link",
          };
        }
      }),
    );

    return attachments;
  }

  async uploadManualJournalAttachments(
    id: string,
    payload: any,
    orgId?: string,
  ) {
    await this.findManualJournal(id, orgId);
    const journal = await this.findManualJournal(id, orgId);
    const incoming = Array.isArray(payload?.attachments)
      ? payload.attachments
      : [];

    if (incoming.length === 0) {
      throw new BadRequestException("At least one attachment is required.");
    }

    if (incoming.length > 5) {
      throw new BadRequestException(
        "You can upload a maximum of 5 attachments per request.",
      );
    }

    const maxSize = 10 * 1024 * 1024;
    const rows = await Promise.all(
      incoming.map(async (raw: any, index: number) => {
        const fileName = (raw?.fileName || raw?.file_name || "")
          .toString()
          .trim();
        const rawFileData = (raw?.fileData || raw?.file_data || "")
          .toString()
          .trim();
        const providedMimeType = (raw?.mimeType || raw?.mime_type || "")
          .toString()
          .trim()
          .toLowerCase();

        if (!fileName) {
          throw new BadRequestException(
            `Attachment ${index + 1} is missing a file name.`,
          );
        }
        if (!rawFileData) {
          throw new BadRequestException(
            `Attachment "${fileName}" is missing file data.`,
          );
        }

        const base64 = this.normalizeAttachmentBase64(rawFileData);
        const mimeType = this.detectAttachmentMimeType(
          fileName,
          providedMimeType,
        );
        if (!this.isAllowedAttachmentMimeType(mimeType)) {
          throw new BadRequestException(
            `Unsupported attachment type for "${fileName}". Only PDF and image files are allowed.`,
          );
        }

        const bytes = Buffer.from(base64, "base64");
        const fileSize = Number(
          raw?.fileSize || raw?.file_size || bytes.length,
        );
        const normalizedFileSize = Number.isFinite(fileSize)
          ? fileSize
          : bytes.length;

        if (normalizedFileSize <= 0) {
          throw new BadRequestException(
            `Attachment "${fileName}" appears to be empty.`,
          );
        }

        if (normalizedFileSize > maxSize) {
          throw new BadRequestException(
            `Attachment "${fileName}" exceeds the 10MB limit.`,
          );
        }

        // Upload to Cloudflare R2
        const publicUrl = await this.r2StorageService.uploadFile(
          fileName,
          bytes,
          mimeType,
        );

        return {
          org_id: orgId || journal.org_id || journal.orgId || this.defaultOrgId,
          outlet_id: journal.outlet_id || journal.outletId || null,
          manual_journal_id: id,
          file_name: fileName,
          file_path: publicUrl, // Now uses the Cloudflare R2 path
          file_size: normalizedFileSize,
        };
      }),
    );

    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("accounts_manual_journal_attachments")
      .insert(rows)
      .select("id, manual_journal_id, file_name, file_size, uploaded_at");

    if (error) {
      this.throwFriendlySupabaseError(
        error,
        `Unable to upload attachments for manual journal "${id}".`,
      );
    }

    return data || [];
  }

  async findFiscalYears(orgId?: string) {
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("accounts_fiscal_years")
      .select("*")
      .eq("is_active", true)
      .order("start_date", { ascending: true });

    if (orgId) {
      query = query.eq("org_id", orgId);
    }

    const { data, error } = await query;
    if (error) {
      throw new BadRequestException(
        `Unable to fetch fiscal years: ${error.message}`,
      );
    }
    return data;
  }

  async saveFiscalYear(
    data: { startDate: string; name?: string },
    orgId?: string,
  ) {
    const supabase = this.supabaseService.getClient();
    const resolvedOrgId = orgId || this.defaultOrgId;

    const start = new Date(data.startDate);
    const end = new Date(start);
    end.setFullYear(end.getFullYear() + 1);
    end.setDate(end.getDate() - 1);

    const name =
      data.name ||
      `FY ${start.getFullYear()}-${String(end.getFullYear()).slice(-2)}`;

    // Deactivate existing active fiscal years for this org first
    await supabase
      .from("accounts_fiscal_years")
      .update({ is_active: false })
      .eq("org_id", resolvedOrgId)
      .eq("is_active", true);

    const { data: created, error } = await supabase
      .from("accounts_fiscal_years")
      .insert({
        org_id: resolvedOrgId,
        name,
        start_date: start.toISOString().split("T")[0],
        end_date: end.toISOString().split("T")[0],
        is_active: true,
      })
      .select()
      .single();

    if (error) {
      throw new BadRequestException(
        `Unable to save fiscal year: ${error.message}`,
      );
    }
    return created;
  }

  async findJournalNumberSettings(scopeInput?: any) {
    const scope = this.parseSettingsScope(scopeInput);
    const defaultSettings = {
      org_id: scope.orgId,
      outlet_id: scope.outletId,
      user_id: scope.userId,
      auto_generate: true,
      prefix: "MJ",
      next_number: 1,
      is_manual_override_allowed: false,
    };

    const supabase = this.supabaseService.getClient();
    const { data, error } = await this.buildJournalSettingsScopeQuery(
      supabase,
      scope,
    )
      .limit(1)
      .maybeSingle();

    if (error) {
      // Keep manual journal create flow alive if table access is temporarily broken.
      if (error.code === "42501" || error.code === "42P01") {
        return defaultSettings;
      }
      throw error;
    }
    const settings = data ?? defaultSettings;
    if (settings.auto_generate === true) {
      const prefix = this.normalizeJournalPrefix(settings.prefix);
      const startNumber = this.normalizeNextNumber(settings.next_number);
      const nextAvailable = await this.getNextAvailableJournalNumber(
        prefix,
        startNumber,
      );
      return {
        ...settings,
        prefix,
        next_number: nextAvailable.currentNumber,
      };
    }
    return settings;
  }

  async updateJournalNumberSettings(data: any) {
    const supabase = this.supabaseService.getClient();
    const scope = this.parseSettingsScope(data);
    const current = await this.findJournalNumberSettings(scope);

    const autoGenerateValue = data.autoGenerate ?? data.auto_generate ?? true;
    const manualOverrideValue =
      data.isManualOverrideAllowed ?? data.is_manual_override_allowed ?? false;

    const dbData = {
      org_id: scope.orgId,
      outlet_id: scope.outletId,
      user_id: scope.userId,
      auto_generate: autoGenerateValue === true,
      prefix: data.prefix ?? data.prefix_value ?? "MJ",
      next_number: Number(data.nextNumber ?? data.next_number ?? 1) || 1,
      is_manual_override_allowed: manualOverrideValue === true,
    };

    let result;
    if (current && current.id) {
      const { data: updated, error } = await supabase
        .from("accounts_journal_number_settings")
        .update(dbData)
        .eq("id", current.id)
        .select()
        .single();
      if (error) throw error;
      result = updated;
    } else {
      const { data: created, error } = await supabase
        .from("accounts_journal_number_settings")
        .insert(dbData)
        .select()
        .single();
      if (error) throw error;
      result = created;
    }
    return result;
  }

  async getNextJournalNumber(scopeInput?: any) {
    const settings = await this.findJournalNumberSettings(scopeInput);
    const autoGenerate = settings.auto_generate === true;
    const prefix = this.normalizeJournalPrefix(settings.prefix);
    const nextNumber = this.normalizeNextNumber(settings.next_number);

    if (autoGenerate) {
      const generated = await this.getNextAvailableJournalNumber(
        prefix,
        nextNumber,
      );
      return {
        ...settings,
        auto_generate: true,
        prefix,
        next_number: generated.currentNumber,
        journal_number: generated.journalNumber,
      };
    }

    return {
      ...settings,
      auto_generate: false,
      prefix,
      next_number: nextNumber,
      journal_number: `${prefix}-${nextNumber}`,
    };
  }

  async findJournalTemplates(scopeInput?: any) {
    const supabase = this.supabaseService.getClient();
    const scope = this.parseSettingsScope(scopeInput);

    let query = supabase
      .from("accounts_journal_templates")
      .select(
        "*, items:accounts_journal_template_items(*, account:accounts(user_account_name, system_account_name))",
      )
      .eq("org_id", scope.orgId)
      .eq("is_active", true)
      .order("template_name", { ascending: true })
      .order("sort_order", {
        ascending: true,
        referencedTable: "items",
      });

    if (scope.outletId) {
      query = query.eq("outlet_id", scope.outletId);
    } else {
      query = query.is("outlet_id", null);
    }

    const { data, error } = await query;
    if (error) {
      this.throwFriendlySupabaseError(
        error,
        "Unable to fetch journal templates.",
      );
    }

    return (data || []).map((template: any) =>
      this.mapJournalTemplate(template),
    );
  }

  async findJournalTemplate(id: string, orgId?: string) {
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("accounts_journal_templates")
      .select(
        "*, items:accounts_journal_template_items(*, account:accounts(user_account_name, system_account_name))",
      )
      .eq("id", id);

    if (orgId) {
      query = query.eq("org_id", orgId);
    }

    const { data, error } = await query.maybeSingle();

    if (error) {
      this.throwFriendlySupabaseError(
        error,
        `Unable to fetch journal template "${id}".`,
      );
    }
    if (!data) {
      throw new NotFoundException(`Journal template "${id}" was not found.`);
    }

    return this.mapJournalTemplate(data);
  }

  async createJournalTemplate(payload: any) {
    const scope = this.parseSettingsScope(payload);

    const templateName = (payload?.templateName || payload?.template_name || "")
      .toString()
      .trim();
    if (!templateName) {
      throw new BadRequestException("Template name is required.");
    }

    const items = this.normalizeTemplateItemsInput(payload?.items);
    if (items.length == 0) {
      throw new BadRequestException(
        "Please add at least one account line in the template.",
      );
    }

    return await db.transaction(async (tx) => {
      const templates = await tx
        .insert(accountsJournalTemplates)
        .values({
          orgId: scope.orgId,
          outletId: scope.outletId,
          templateName: templateName,
          referenceNumber:
            (payload?.referenceNumber ?? payload?.reference_number ?? null)
              ?.toString()
              .trim() || null,
          notes: (payload?.notes ?? null)?.toString() || null,
          reportingMethod:
            (
              payload?.reportingMethod ??
              payload?.reporting_method ??
              "accrual_and_cash"
            )
              ?.toString()
              .trim() || "accrual_and_cash",
          currencyCode:
            (payload?.currencyCode ?? payload?.currency_code ?? "INR")
              ?.toString()
              .trim() || "INR",
          enterAmount:
            payload?.enterAmount === true || payload?.enter_amount === true,
          isActive: true,
        })
        .returning();

      const created = templates[0];
      if (!created) throw new Error("Failed to create journal template header");

      const itemRows = items.map((item, index) => ({
        orgId: scope.orgId,
        outletId: scope.outletId,
        templateId: created.id,
        accountId: item.account_id,
        description: item.description ?? null,
        contactId: item.contact_id ?? null,
        contactType: item.contact_type ?? null,
        type: item.type ?? null,
        debit: this.toNumber(item.debit).toString(),
        credit: this.toNumber(item.credit).toString(),
        sortOrder: item.sort_order ?? index + 1,
      }));

      await tx.insert(accountsJournalTemplateItems).values(itemRows);

      return this.findJournalTemplate(created.id);
    });
  }

  async updateJournalTemplate(id: string, payload: any) {
    const existing = await this.findJournalTemplate(id);
    const scope = this.parseSettingsScope(payload);

    const templateName = (
      payload?.templateName ??
      payload?.template_name ??
      existing.template_name ??
      existing.templateName ??
      ""
    )
      .toString()
      .trim();
    if (!templateName) {
      throw new BadRequestException("Template name is required.");
    }

    const updateData: any = {
      orgId: scope.orgId,
      outletId: scope.outletId,
      templateName: templateName,
      referenceNumber:
        (
          payload?.referenceNumber ??
          payload?.reference_number ??
          existing.reference_number ??
          existing.referenceNumber ??
          null
        )
          ?.toString()
          .trim() || null,
      notes: (payload?.notes ?? existing.notes ?? null)?.toString() || null,
      reportingMethod:
        (
          payload?.reportingMethod ??
          payload?.reporting_method ??
          existing.reporting_method ??
          existing.reportingMethod ??
          "accrual_and_cash"
        )
          ?.toString()
          .trim() || "accrual_and_cash",
      currencyCode:
        (
          payload?.currencyCode ??
          payload?.currency_code ??
          existing.currency_code ??
          existing.currencyCode ??
          "INR"
        )
          ?.toString()
          .trim() || "INR",
      enterAmount:
        payload?.enterAmount === true ||
        payload?.enter_amount === true ||
        existing.enter_amount === true ||
        existing.enterAmount === true,
      updatedAt: new Date(),
    };

    return await db.transaction(async (tx) => {
      await tx
        .update(accountsJournalTemplates)
        .set(updateData)
        .where(eq(accountsJournalTemplates.id, id));

      if (Array.isArray(payload?.items)) {
        const normalizedItems = this.normalizeTemplateItemsInput(payload.items);

        await tx
          .delete(accountsJournalTemplateItems)
          .where(eq(accountsJournalTemplateItems.templateId, id));

        if (normalizedItems.length > 0) {
          const itemRows = normalizedItems.map((item, index) => ({
            orgId: scope.orgId,
            outletId: scope.outletId,
            templateId: id,
            accountId: item.account_id,
            description: item.description ?? null,
            contactId: item.contact_id ?? null,
            contactType: item.contact_type ?? null,
            type: item.type ?? null,
            debit: this.toNumber(item.debit).toString(),
            credit: this.toNumber(item.credit).toString(),
            sortOrder: item.sort_order ?? index + 1,
          }));

          await tx.insert(accountsJournalTemplateItems).values(itemRows);
        }
      }

      return this.findJournalTemplate(id);
    });
  }

  async deleteJournalTemplate(id: string, orgId?: string) {
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("accounts_journal_templates")
      .delete()
      .eq("id", id);

    if (orgId) {
      query = query.eq("org_id", orgId);
    }

    const { error } = await query;

    if (error) {
      this.throwFriendlySupabaseError(
        error,
        `Unable to delete journal template "${id}".`,
      );
    }
    return { success: true };
  }

  private parseSettingsScope(input?: any): {
    orgId: string;
    outletId: string | null;
    userId: string | null;
  } {
    const orgRaw = input?.orgId ?? input?.org_id;
    const outletRaw = input?.outletId ?? input?.outlet_id;
    const userRaw = input?.userId ?? input?.user_id ?? input?.createdBy;

    const orgId =
      typeof orgRaw === "string" && orgRaw.trim().length > 0
        ? orgRaw.trim()
        : this.defaultOrgId;
    const outletId =
      typeof outletRaw === "string" && outletRaw.trim().length > 0
        ? outletRaw.trim()
        : null;
    const userId =
      typeof userRaw === "string" && userRaw.trim().length > 0
        ? userRaw.trim()
        : null;

    return { orgId, outletId, userId };
  }

  private buildJournalSettingsScopeQuery(
    supabase: any,
    scope: { orgId: string; outletId: string | null; userId: string | null },
  ) {
    let query = supabase
      .from("accounts_journal_number_settings")
      .select("*")
      .eq("org_id", scope.orgId);

    if (scope.outletId) {
      query = query.eq("outlet_id", scope.outletId);
    } else {
      query = query.is("outlet_id", null);
    }

    if (scope.userId) {
      query = query.eq("user_id", scope.userId);
    } else {
      query = query.is("user_id", null);
    }

    return query;
  }

  private normalizeJournalPrefix(prefix: any): string {
    const parsed = (prefix ?? "MJ").toString().trim();
    return parsed.length > 0 ? parsed : "MJ";
  }

  private normalizeNextNumber(value: any): number {
    const parsed =
      typeof value === "number" ? value : parseInt(value?.toString() ?? "", 10);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : 1;
  }

  private async journalNumberExists(
    journalNumber: string,
    excludeId?: string,
  ): Promise<boolean> {
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("accounts_manual_journals")
      .select("id")
      .eq("journal_number", journalNumber);

    if (excludeId) {
      query = query.neq("id", excludeId);
    }

    const { data, error } = await query.maybeSingle();
    if (error) {
      this.throwFriendlySupabaseError(
        error,
        "Unable to validate journal number uniqueness.",
      );
    }
    return !!data;
  }

  private async getNextAvailableJournalNumber(
    prefix: string,
    startNumber: number,
  ): Promise<{
    journalNumber: string;
    currentNumber: number;
    nextNumberAfter: number;
  }> {
    let current = this.normalizeNextNumber(startNumber);
    const normalizedPrefix = this.normalizeJournalPrefix(prefix);
    const maxAttempts = 10000;

    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      const candidate = `${normalizedPrefix}-${current}`;
      const exists = await this.journalNumberExists(candidate);
      if (!exists) {
        return {
          journalNumber: candidate,
          currentNumber: current,
          nextNumberAfter: current + 1,
        };
      }
      current += 1;
    }

    throw new ConflictException(
      `Unable to generate next journal number for prefix "${normalizedPrefix}".`,
    );
  }

  async findContacts(orgId?: string) {
    const supabase = this.supabaseService.getClient();

    let cQuery = supabase
      .from("customers")
      .select("id, display_name, customer_type, is_active")
      .eq("is_active", true)
      .order("display_name", { ascending: true });

    let vQuery = supabase
      .from("vendors")
      .select("id, display_name, vendor_type, is_active")
      .eq("is_active", true)
      .order("display_name", { ascending: true });

    if (orgId) {
      cQuery = cQuery.eq("org_id", orgId);
      vQuery = vQuery.eq("org_id", orgId);
    }

    const [customersRes, vendorsRes] = await Promise.all([cQuery, vQuery]);

    if (customersRes.error && vendorsRes.error) {
      throw customersRes.error;
    }

    const customers = (customersRes.data || []).map((c) => ({
      id: (c.id ?? "").toString().trim(),
      displayName: (c.display_name ?? "").toString().trim(),
      type: "customer",
      contact_type: "customer",
      customer_type: (c.customer_type ?? "").toString().trim() || null,
    }));

    const vendors = (vendorsRes.data || []).map((v) => ({
      id: (v.id ?? "").toString().trim(),
      displayName: (v.display_name ?? "").toString().trim(),
      type: "vendor",
      contact_type: "vendor",
      vendor_type: (v.vendor_type ?? "").toString().trim() || null,
    }));

    const dedupe = new Set<string>();
    const contacts = [...customers, ...vendors]
      .filter((c) => c.id.length > 0 && c.displayName.length > 0)
      .filter((c) => {
        const key = `${c.contact_type}:${c.id}`;
        if (dedupe.has(key)) return false;
        dedupe.add(key);
        return true;
      })
      .sort((a, b) => a.displayName.localeCompare(b.displayName));

    return contacts;
  }

  async searchContacts(query: string, orgId?: string) {
    const supabase = this.supabaseService.getClient();

    let cQuery = supabase
      .from("customers")
      .select("id, display_name, customer_type, is_active")
      .eq("is_active", true)
      .ilike("display_name", `%${query}%`)
      .limit(20);

    let vQuery = supabase
      .from("vendors")
      .select("id, display_name, vendor_type, is_active")
      .eq("is_active", true)
      .ilike("display_name", `%${query}%`)
      .limit(20);

    if (orgId) {
      cQuery = cQuery.eq("org_id", orgId);
      vQuery = vQuery.eq("org_id", orgId);
    }

    const [customersRes, vendorsRes] = await Promise.all([cQuery, vQuery]);

    const customers = (customersRes.data || []).map((c) => ({
      id: c.id.toString(),
      displayName: c.display_name,
      type: "customer",
      contact_type: "customer",
    }));

    const vendors = (vendorsRes.data || []).map((v) => ({
      id: v.id.toString(),
      displayName: v.display_name,
      type: "vendor",
      contact_type: "vendor",
    }));

    return [...customers, ...vendors].sort((a, b) =>
      a.displayName.localeCompare(b.displayName),
    );
  }

  // --- Recurring Journal Methods ---

  async findRecurringJournals(orgId?: string) {
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("accounts_recurring_journals")
      .select(
        "*, items:accounts_recurring_journal_items(*, account:accounts(id, user_account_name, system_account_name))",
      );

    if (orgId) {
      query = query.eq("org_id", orgId);
    }

    const { data, error } = await query.order("created_at", {
      ascending: false,
    });

    if (error) {
      this.throwFriendlySupabaseError(
        error,
        "Unable to fetch recurring journals.",
      );
    }
    return (data || []).map((journal) => this.mapRecurringJournal(journal));
  }

  async findRecurringJournal(id: string, orgId?: string) {
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("accounts_recurring_journals")
      .select(
        "*, items:accounts_recurring_journal_items(*, account:accounts(id, user_account_name, system_account_name))",
      )
      .eq("id", id);

    if (orgId) {
      query = query.eq("org_id", orgId);
    }

    const { data, error } = await query.maybeSingle();

    if (error) {
      this.throwFriendlySupabaseError(
        error,
        `Unable to fetch recurring journal "${id}".`,
      );
    }
    if (!data) {
      throw new NotFoundException(`Recurring journal "${id}" was not found.`);
    }
    return this.mapRecurringJournal(data);
  }

  async createRecurringJournal(dto: any) {
    const { items, ...header } = dto;
    const normalizedItems = this.normalizeManualJournalItemsInput(items);
    const scope = this.parseSettingsScope(header);

    const journalId = await db.transaction(async (tx) => {
      const inserts = await tx
        .insert(accountsRecurringJournals)
        .values({
          profileName: header.profileName || header.profile_name,
          repeatEvery: header.repeatEvery || header.repeat_every,
          interval: header.interval || 1,
          startDate: header.startDate || header.start_date,
          endDate: header.endDate || header.end_date || null,
          neverExpires: header.neverExpires ?? header.never_expires ?? true,
          referenceNumber:
            header.referenceNumber || header.reference_number || null,
          notes: header.notes || null,
          currencyCode: header.currency || header.currency_code || "INR",
          reportingMethod:
            header.reportingMethod ||
            header.reporting_method ||
            "accrual_and_cash",
          orgId: scope.orgId,
          outletId: scope.outletId,
          createdById: header.createdBy || header.created_by || scope.userId,
          status: "active",
        })
        .returning();

      const journal = inserts[0];
      if (!journal)
        throw new Error("Failed to create recurring journal header");

      await this.replaceRecurringJournalItems(journal.id, normalizedItems, tx);

      return journal.id;
    });

    return this.findRecurringJournal(journalId);
  }

  async updateRecurringJournal(id: string, dto: any) {
    const { items, ...header } = dto;

    const dbData: any = {
      updatedAt: new Date(),
    };

    if (header.profileName) dbData.profileName = header.profileName;
    if (header.repeatEvery) dbData.repeatEvery = header.repeatEvery;
    if (header.interval) dbData.interval = header.interval;
    if (header.startDate) dbData.startDate = header.startDate;
    if (header.endDate !== undefined) dbData.endDate = header.endDate;
    if (header.neverExpires !== undefined)
      dbData.neverExpires = header.neverExpires;
    if (header.referenceNumber !== undefined)
      dbData.referenceNumber = header.referenceNumber;
    if (header.notes !== undefined) dbData.notes = header.notes;
    if (header.currency || header.currency_code)
      dbData.currencyCode = header.currency || header.currency_code;
    if (header.reportingMethod || header.reporting_method)
      dbData.reportingMethod =
        header.reportingMethod || header.reporting_method;

    return await db.transaction(async (tx) => {
      await tx
        .update(accountsRecurringJournals)
        .set(dbData)
        .where(eq(accountsRecurringJournals.id, id));

      if (items) {
        const normalizedItems = this.normalizeManualJournalItemsInput(items);
        await this.replaceRecurringJournalItems(id, normalizedItems, tx);
      }

      return this.findRecurringJournal(id);
    });
  }

  async updateRecurringJournalStatus(id: string, status: string) {
    const supabase = this.supabaseService.getClient();
    const { error } = await supabase
      .from("accounts_recurring_journals")
      .update({ status: status })
      .eq("id", id);

    if (error) {
      this.throwFriendlySupabaseError(error, "Unable to update status.");
    }
    return this.findRecurringJournal(id);
  }

  async findManualJournalByRecurring(
    recurringJournalId: string,
    journalDate: string,
  ) {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("accounts_manual_journals")
      .select("id")
      .eq("recurring_journal_id", recurringJournalId)
      .eq("journal_date", journalDate)
      .maybeSingle();

    if (error) return null;
    return data;
  }

  async findRecurringChildJournals(recurringJournalId: string, orgId?: string) {
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("accounts_manual_journals")
      .select("*")
      .eq("recurring_journal_id", recurringJournalId);

    if (orgId) {
      query = query.eq("org_id", orgId);
    }

    const { data, error } = await query.order("journal_date", {
      ascending: false,
    });

    if (error) {
      this.throwFriendlySupabaseError(error, "Unable to fetch child journals.");
    }

    return (data || []).map((j) => this.mapManualJournal(j));
  }

  async generateManualJournalFromRecurring(
    id: string,
    generationDate?: string,
  ) {
    const journal = await this.findRecurringJournal(id);
    const dateToUse = generationDate || new Date().toISOString().split("T")[0];

    // Create manual journal DTO from recurring journal
    const dto = {
      profile_name: `Generated: ${journal.profileName}`,
      journal_number: null, // Auto-generate
      journal_date: dateToUse,
      reference_number: journal.referenceNumber,
      notes: journal.notes,
      currency_code: journal.currency,
      reporting_method: journal.reportingMethod,
      journal_status: "posted",
      recurring_journal_id: id,
      items: journal.items.map((item) => ({
        accountId: item.accountId,
        description: item.description,
        contactId: item.contactId,
        contactType: item.contactType,
        debit: item.debit,
        credit: item.credit,
      })),
    };

    const newJournal = await this.createManualJournal(dto);

    // Update the recurring journal's last generated date
    await db
      .update(accountsRecurringJournals)
      .set({ lastGeneratedDate: dateToUse })
      .where(eq(accountsRecurringJournals.id, id));

    return newJournal;
  }

  async cloneRecurringJournal(id: string) {
    const supabase = this.supabaseService.getClient();

    const { data: original, error: fetchError } = await supabase
      .from("accounts_recurring_journals")
      .select("*")
      .eq("id", id)
      .single();

    if (fetchError) {
      this.throwFriendlySupabaseError(
        fetchError,
        `Recurring Journal not found.`,
      );
    }

    const { data: items, error: itemsError } = await supabase
      .from("accounts_recurring_journal_items")
      .select("*")
      .eq("recurring_journal_id", id)
      .order("sort_order", { ascending: true });

    if (itemsError) {
      this.throwFriendlySupabaseError(
        itemsError,
        "Unable to fetch recurring journal items.",
      );
    }

    const dbData = {
      profile_name: `Copy of ${original.profile_name}`,
      repeat_every: original.repeat_every,
      interval: original.interval,
      start_date: new Date().toISOString().split("T")[0],
      end_date: original.end_date,
      never_expires: original.never_expires,
      reference_number: original.reference_number,
      notes: original.notes,
      currency_code: original.currency_code,
      reporting_method: original.reporting_method,
      org_id: original.org_id,
      outlet_id: original.outlet_id,
      status: "inactive",
      created_by: original.created_by,
    };

    const { data: createdJournal, error: createError } = await supabase
      .from("accounts_recurring_journals")
      .insert(dbData)
      .select()
      .single();

    if (createError) {
      this.throwFriendlySupabaseError(
        createError,
        "Failed to clone recurring journal.",
      );
    }

    if (items && items.length > 0) {
      const newItems = items.map((item) => ({
        recurring_journal_id: createdJournal.id,
        account_id: item.account_id,
        description: item.description,
        contact_id: item.contact_id,
        contact_type: item.contact_type,
        debit: item.debit,
        credit: item.credit,
        sort_order: item.sort_order,
      }));

      const { error: itemsInsertError } = await supabase
        .from("accounts_recurring_journal_items")
        .insert(newItems);

      if (itemsInsertError) {
        await supabase
          .from("accounts_recurring_journals")
          .delete()
          .eq("id", createdJournal.id);
        this.throwFriendlySupabaseError(
          itemsInsertError,
          "Failed to clone recurring journal items.",
        );
      }
    }

    return this.findRecurringJournal(createdJournal.id);
  }

  async deleteRecurringJournal(id: string) {
    const supabase = this.supabaseService.getClient();
    const { error } = await supabase
      .from("accounts_recurring_journals")
      .delete()
      .eq("id", id);

    if (error) {
      this.throwFriendlySupabaseError(
        error,
        "Unable to delete recurring journal.",
      );
    }
    return { success: true };
  }

  private async replaceRecurringJournalItems(
    journalId: string,
    items: any[],
    tx?: any,
  ): Promise<void> {
    const dbClient = tx || db;

    await dbClient
      .delete(accountsRecurringJournalItems)
      .where(eq(accountsRecurringJournalItems.recurringJournalId, journalId));

    if (items.length === 0) return;

    const insertRows = items.map((item, index) => ({
      recurringJournalId: journalId,
      accountId: item.account_id || item.accountId,
      description: item.description || null,
      contactId: item.contact_id || item.contactId || null,
      contactType: item.contact_type || item.contactType || null,
      contactName: item.contact_name || item.contactName || null,
      debit: this.toNumber(item.debit).toString(),
      credit: this.toNumber(item.credit).toString(),
      sortOrder: item.sort_order || item.sortOrder || index + 1,
    }));

    await dbClient.insert(accountsRecurringJournalItems).values(insertRows);
  }

  private mapRecurringJournal(data: any) {
    return {
      id: data.id,
      profileName: data.profile_name,
      repeatEvery: data.repeat_every,
      interval: data.interval,
      startDate: data.start_date,
      endDate: data.end_date,
      neverExpires: data.never_expires,
      referenceNumber: data.reference_number,
      notes: data.notes,
      currency: data.currency_code,
      reportingMethod: data.reporting_method,
      status: data.status,
      lastGeneratedDate: data.last_generated_date,
      createdAt: data.created_at,
      updatedAt: data.updated_at,
      items: (data.items || []).map((item: any) => ({
        id: item.id,
        accountId: item.account_id || item.accountId,
        accountName:
          item.account?.user_account_name ||
          item.account?.system_account_name ||
          "Unknown Account",
        description: item.description || "",
        contactId: item.contact_id || item.contactId,
        contactType: item.contact_type || item.contactType,
        contactName:
          item.contact_name ||
          item.contactName ||
          item.customer?.display_name ||
          item.vendor?.display_name ||
          "",
        debit: Number(item.debit || 0),
        credit: Number(item.credit || 0),
        sortOrder: item.sort_order,
      })),
    };
  }

  private normalizeManualJournalStatus(
    value: string | null | undefined,
  ): "draft" | "posted" | "cancelled" {
    const normalized = (value || "draft").toString().trim().toLowerCase();
    if (normalized === "draft") return "draft";
    if (normalized === "posted" || normalized === "published") return "posted";
    if (normalized === "cancelled" || normalized === "void_status") {
      return "cancelled";
    }
    throw new BadRequestException(
      `Invalid manual journal status "${value}". Allowed values: draft, posted, cancelled.`,
    );
  }

  private getDbStatusForCreate(apiStatus: "draft" | "posted" | "cancelled") {
    // Keep DB compatibility with existing enum values while API uses posted/cancelled.
    if (apiStatus === "posted") {
      return "published";
    }
    if (apiStatus === "cancelled") {
      return "void_status";
    }
    return "draft";
  }

  private normalizeManualJournalItemsInput(items: any[]): any[] {
    if (!Array.isArray(items)) {
      return [];
    }

    return items.map((raw, index) => ({
      account_id: this.normalizeUuid(raw.accountId || raw.account_id),
      description: raw.description || null,
      contact_id: this.normalizeUuid(raw.contactId || raw.contact_id),
      contact_type: raw.contactType || raw.contact_type || null,
      contact_name: raw.contactName || raw.contact_name || null,
      debit: this.toNumber(raw.debit),
      credit: this.toNumber(raw.credit),
      sort_order: raw.sortOrder || raw.sort_order || index + 1,
    }));
  }

  private normalizeTemplateItemsInput(items: any[]): any[] {
    if (!Array.isArray(items)) {
      return [];
    }

    return items
      .map((raw, index) => ({
        account_id: this.normalizeUuid(raw.accountId || raw.account_id),
        description: (raw.description ?? null)?.toString().trim() || null,
        contact_id: this.normalizeUuid(raw.contactId || raw.contact_id),
        contact_type:
          (raw.contactType ?? raw.contact_type ?? null)?.toString().trim() ||
          null,
        type: (raw.type ?? null)?.toString().trim().toLowerCase() || null,
        debit: this.toNumber(raw.debit),
        credit: this.toNumber(raw.credit),
        sort_order: raw.sortOrder || raw.sort_order || index + 1,
      }))
      .filter((item) => !!item.account_id)
      .map((item) => ({
        ...item,
        type:
          item.type === "debit" || item.type === "credit" ? item.type : null,
      }));
  }

  private getPersistableDraftItems(items: any[]): any[] {
    if (!Array.isArray(items)) return [];
    return items.filter((item) => !!(item.account_id || item.accountId));
  }

  private validateManualJournalItems(items: any[]) {
    if (!Array.isArray(items) || items.length < 2) {
      throw new BadRequestException(
        "A manual journal must contain at least 2 line items.",
      );
    }

    let totalDebit = 0;
    let totalCredit = 0;

    for (const item of items) {
      if (!item.account_id && !item.accountId) {
        throw new BadRequestException(
          "Each line item must include an account.",
        );
      }

      const debit = this.toNumber(item.debit);
      const credit = this.toNumber(item.credit);
      if (debit < 0 || credit < 0) {
        throw new BadRequestException(
          "Debit and credit amounts cannot be negative.",
        );
      }

      totalDebit += debit;
      totalCredit += credit;
    }

    if (totalDebit <= 0 && totalCredit <= 0) {
      throw new BadRequestException(
        "Manual journal must contain at least one non-zero debit or credit line.",
      );
    }

    if (Math.abs(totalDebit - totalCredit) > 0.01) {
      throw new BadRequestException(
        "Journal entry is not balanced. Total debit must equal total credit.",
      );
    }
  }

  private async ensureJournalNumberUnique(
    journalNumber: string,
    excludeId?: string,
  ) {
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("accounts_manual_journals")
      .select("id")
      .eq("journal_number", journalNumber);

    if (excludeId) {
      query = query.neq("id", excludeId);
    }

    const { data: existing, error } = await query.maybeSingle();
    if (error) {
      this.throwFriendlySupabaseError(
        error,
        "Unable to validate journal number uniqueness.",
      );
    }

    if (existing) {
      throw new ConflictException(
        `Journal number "${journalNumber}" already exists.`,
      );
    }
  }

  private async ensureDraftManualJournal(
    id: string,
    action: string,
    orgId?: string,
  ) {
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("accounts_manual_journals")
      .select("id, status")
      .eq("id", id);

    if (orgId) {
      query = query.eq("org_id", orgId);
    }

    const { data, error } = await query.maybeSingle();

    if (error) {
      this.throwFriendlySupabaseError(
        error,
        `Unable to fetch journal for ${action}.`,
      );
    }
    if (!data) {
      throw new NotFoundException(`Journal with ID "${id}" not found.`);
    }
    if (this.normalizeManualJournalStatus(data.status) !== "draft") {
      throw new ConflictException(`Only "draft" journals can be ${action}.`);
    }
    return data;
  }

  private async replaceManualJournalItems(
    manualJournalId: string,
    items: any[],
    tx?: any,
  ): Promise<any[]> {
    const dbClient = tx || db;

    await dbClient
      .delete(accountsManualJournalItems)
      .where(eq(accountsManualJournalItems.manualJournalId, manualJournalId));

    if (items.length === 0) return;

    const insertRows = items.map((item, index) => ({
      manualJournalId,
      accountId: item.account_id || item.accountId,
      description: item.description || null,
      contactId: item.contact_id || item.contactId || null,
      contactType: item.contact_type || item.contactType || null,
      contactName: item.contact_name || item.contactName || null,
      debit: this.toNumber(item.debit).toString(),
      credit: this.toNumber(item.credit).toString(),
      sortOrder: item.sort_order || item.sortOrder || index + 1,
    }));

    return await dbClient
      .insert(accountsManualJournalItems)
      .values(insertRows)
      .returning();
  }

  private async setManualJournalStatus(
    manualJournalId: string,
    apiStatus: "draft" | "posted" | "cancelled",
  ): Promise<void> {
    const supabase = this.supabaseService.getClient();
    const candidates =
      apiStatus === "posted"
        ? ["posted", "published"]
        : apiStatus === "cancelled"
          ? ["cancelled", "void_status"]
          : ["draft"];

    let lastError: any = null;

    for (const candidate of candidates) {
      const { error } = await supabase
        .from("accounts_manual_journals")
        .update({ status: candidate })
        .eq("id", manualJournalId);

      if (!error) {
        return;
      }

      lastError = error;

      if (!this.isEnumValueError(error)) {
        throw error;
      }
    }

    if (lastError) {
      throw new BadRequestException(
        `Manual journal status "${apiStatus}" is not supported by current database enum. Please run status enum migration.`,
      );
    }
  }

  private isEnumValueError(error: any): boolean {
    const code = error?.code?.toString() || "";
    const message = (error?.message || "").toString().toLowerCase();
    return (
      code === "22P02" ||
      message.includes("invalid input value for enum") ||
      message.includes("accounts_manual_journal_status")
    );
  }

  private isUniqueViolationError(error: any): boolean {
    const code = error?.code?.toString() || "";
    const message = (error?.message || "").toString().toLowerCase();
    return (
      code === "23505" ||
      message.includes("duplicate key value") ||
      message.includes("unique constraint")
    );
  }

  private throwFriendlySupabaseError(error: any, fallback: string): never {
    const code = (error?.code ?? "").toString();
    const rawMessage = (error?.message ?? fallback).toString().trim();
    const message = rawMessage.length > 0 ? rawMessage : fallback;

    if (code === "23505") {
      throw new ConflictException(
        message.toLowerCase().includes("journal_number")
          ? "Journal number already exists. Please use the next available number."
          : message,
      );
    }

    if (code === "23503") {
      throw new BadRequestException(`Invalid reference selected. ${message}`);
    }

    if (code === "22P02") {
      throw new BadRequestException(`Invalid value provided. ${message}`);
    }

    if (code === "42501") {
      throw new BadRequestException(
        `Permission error while saving journal data. ${message}`,
      );
    }

    throw new BadRequestException(message);
  }

  private async assertDateInActiveFiscalYear(journalDateInput: any) {
    const journalDate = this.normalizeDateOnly(journalDateInput);
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("accounts_fiscal_years")
      .select("id")
      .eq("is_active", true)
      .lte("start_date", journalDate)
      .gte("end_date", journalDate)
      .limit(1);

    if (error) {
      this.throwFriendlySupabaseError(
        error,
        "Unable to validate fiscal year for selected journal date.",
      );
    }
    if (!Array.isArray(data) || data.length === 0) {
      throw new BadRequestException(
        "The selected journal date is in a closed accounting period.",
      );
    }
  }

  private normalizeDateOnly(value: any): string {
    const raw = (value ?? "").toString().trim();
    const dmyMatch = raw.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
    if (dmyMatch) {
      const day = Number.parseInt(dmyMatch[1], 10);
      const month = Number.parseInt(dmyMatch[2], 10);
      const year = Number.parseInt(dmyMatch[3], 10);
      if (
        Number.isInteger(day) &&
        Number.isInteger(month) &&
        Number.isInteger(year) &&
        day >= 1 &&
        day <= 31 &&
        month >= 1 &&
        month <= 12
      ) {
        const utcDate = new Date(Date.UTC(year, month - 1, day));
        if (
          utcDate.getUTCFullYear() === year &&
          utcDate.getUTCMonth() === month - 1 &&
          utcDate.getUTCDate() === day
        ) {
          return `${year.toString().padStart(4, "0")}-${month
            .toString()
            .padStart(2, "0")}-${day.toString().padStart(2, "0")}`;
        }
      }
      throw new BadRequestException("Invalid journal date.");
    }

    if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) {
      return raw;
    }
    if (/^\d{4}-\d{2}-\d{2}T/.test(raw)) {
      return raw.slice(0, 10);
    }
    const parsed = new Date(raw);
    if (Number.isNaN(parsed.getTime())) {
      throw new BadRequestException("Invalid journal date.");
    }
    return parsed.toISOString().slice(0, 10);
  }

  private calculateManualJournalTotal(items: any[]): number {
    return items.reduce((sum, item) => sum + this.toNumber(item.debit), 0);
  }

  private toNumber(value: any): number {
    const parsed = typeof value === "number" ? value : parseFloat(value ?? "0");
    return Number.isFinite(parsed) ? parsed : 0;
  }

  private normalizeUuid(value: any): string | null {
    if (value === null || value === undefined) {
      return null;
    }

    const raw = value.toString().trim().replace(/[\\"]/g, "").trim();
    if (raw.length === 0) {
      return null;
    }
    const uuidRegex =
      /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$/;
    return uuidRegex.test(raw) ? raw : null;
  }

  private mapJournalTemplate(template: any) {
    const items = (template.items || []).map((item: any) => ({
      ...item,
      account_name:
        item.account_name ||
        item.account?.user_account_name ||
        item.account?.system_account_name ||
        "",
      debit: this.toNumber(item.debit),
      credit: this.toNumber(item.credit),
    }));

    return {
      ...template,
      items,
      enter_amount: template.enter_amount === true,
      total_amount: items.reduce(
        (sum: number, item: any) =>
          sum + Math.max(this.toNumber(item.debit), this.toNumber(item.credit)),
        0,
      ),
    };
  }

  private mapManualJournal(journal: any) {
    if (!journal) return null;

    const items = (journal.items || []).map((item: any) => ({
      ...item,
      account_name:
        item.account_name ||
        item.accountName ||
        item.account?.userAccountName ||
        item.account?.systemAccountName ||
        "",
      contact_name:
        item.contact_name ||
        item.contactName ||
        item.customer?.display_name ||
        item.vendor?.display_name ||
        "",
      debit: this.toNumber(item.debit),
      credit: this.toNumber(item.credit),
    }));

    return {
      ...journal,
      status: this.normalizeManualJournalStatus(journal.status),
      items,
      total_amount:
        journal.total_amount ??
        journal.totalAmount ??
        this.calculateManualJournalTotal(items),
    };
  }

  private normalizeAttachmentBase64(value: string): string {
    const trimmed = (value || "").trim();
    const raw = trimmed.includes(",")
      ? trimmed.split(",").pop() || ""
      : trimmed;
    const cleaned = raw.replace(/\s+/g, "");

    if (!cleaned) {
      throw new BadRequestException("Attachment data is empty.");
    }

    const bytes = Buffer.from(cleaned, "base64");
    if (bytes.length === 0) {
      throw new BadRequestException("Attachment data is invalid.");
    }

    return cleaned;
  }

  private detectAttachmentMimeType(
    fileName: string,
    providedMimeType: string,
  ): string {
    if (providedMimeType) {
      return providedMimeType;
    }

    const normalizedName = fileName.toLowerCase();
    if (normalizedName.endsWith(".pdf")) return "application/pdf";
    if (normalizedName.endsWith(".png")) return "image/png";
    if (normalizedName.endsWith(".jpg") || normalizedName.endsWith(".jpeg")) {
      return "image/jpeg";
    }
    if (normalizedName.endsWith(".webp")) return "image/webp";
    if (normalizedName.endsWith(".gif")) return "image/gif";

    return "application/octet-stream";
  }

  private isAllowedAttachmentMimeType(mimeType: string): boolean {
    return [
      "application/pdf",
      "image/png",
      "image/jpeg",
      "image/jpg",
      "image/webp",
      "image/gif",
    ].includes((mimeType || "").toLowerCase());
  }

  // --- Reports Methods ---

  async getProfitAndLossReport(
    startDate: string,
    endDate: string,
    orgId?: string,
  ) {
    const conditions: any[] = [
      sql`t.transaction_date >= ${new Date(startDate).toISOString()}`,
      sql`t.transaction_date <= ${new Date(endDate).toISOString()}`,
      sql`COALESCE(a.user_account_name, a.system_account_name) != 'Opening Balance Offset'`,
    ];
    if (orgId) {
      conditions.push(sql`t.org_id = ${orgId}`);
    }

    const whereClause = sql.join(conditions, sql` AND `);

    const query = sql`
      SELECT 
        a.account_type as "accountType",
        COALESCE(a.user_account_name, a.system_account_name) as "accountName",
        a.id as "accountId",
        SUM(t.debit) as "totalDebit",
        SUM(t.credit) as "totalCredit"
      FROM account_transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
      GROUP BY a.account_type, COALESCE(a.user_account_name, a.system_account_name), a.id
    `;

    const result = await db.execute(query);
    const rows = result as any[];

    const report = {
      operatingIncome: [],
      costOfGoodsSold: [],
      operatingExpenses: [],
    };

    let totalIncome = 0;
    let totalCogs = 0;
    let totalExpenses = 0;

    for (const row of rows as any[]) {
      const isIncome =
        row.accountType?.toLowerCase().includes("income") ||
        row.accountType?.toLowerCase().includes("sales");
      const isCogs =
        row.accountType?.toLowerCase().includes("cogs") ||
        row.accountType?.toLowerCase().includes("cost");
      const isExpense = row.accountType?.toLowerCase().includes("expense");

      const totalDebit = Number(row.totalDebit);
      const totalCredit = Number(row.totalCredit);
      const netAmount = isIncome
        ? totalCredit - totalDebit
        : totalDebit - totalCredit;

      const item = {
        accountId: row.accountId,
        accountName: row.accountName,
        accountType: row.accountType,
        netAmount,
      };

      if (isIncome) {
        report.operatingIncome.push(item);
        totalIncome += netAmount;
      } else if (isCogs) {
        report.costOfGoodsSold.push(item);
        totalCogs += netAmount;
      } else if (isExpense) {
        report.operatingExpenses.push(item);
        totalExpenses += netAmount;
      }
    }

    return {
      period: { startDate, endDate },
      report,
      summary: {
        totalIncome,
        totalCogs,
        grossProfit: totalIncome - totalCogs,
        totalExpenses,
        netProfit: totalIncome - totalCogs - totalExpenses,
      },
    };
  }

  async getGeneralLedgerReport(
    startDate: string,
    endDate: string,
    orgId?: string,
  ) {
    const conditions: any[] = [
      sql`t.transaction_date >= ${new Date(startDate).toISOString()}`,
      sql`t.transaction_date <= ${new Date(endDate).toISOString()}`,
    ];
    if (orgId) {
      conditions.push(sql`t.org_id = ${orgId}`);
    }

    const whereClause = sql.join(conditions, sql` AND `);

    const query = sql`
      SELECT 
        a.account_type as "accountType",
        COALESCE(a.user_account_name, a.system_account_name) as "accountName",
        a.account_code as "accountCode",
        a.id as "accountId",
        SUM(t.debit) as "totalDebit",
        SUM(t.credit) as "totalCredit"
      FROM account_transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
      GROUP BY a.account_type, COALESCE(a.user_account_name, a.system_account_name), a.account_code, a.id
    `;

    const result = await db.execute(query);
    const rows = result as any[];

    return {
      period: { startDate, endDate },
      accounts: rows.map((r: any) => ({
        accountId: r.accountId,
        accountName: r.accountName,
        accountCode: r.accountCode,
        accountType: r.accountType,
        debit: Number(r.totalDebit),
        credit: Number(r.totalCredit),
        netBalance: Number(r.totalDebit) - Number(r.totalCredit),
      })),
    };
  }

  async getAccountTransactionsReport(
    accountId: string,
    startDate: string,
    endDate: string,
    orgId?: string,
    contactId?: string,
    contactType?: string,
  ) {
    const conditions: any[] = [];

    if (accountId) {
      conditions.push(sql`t.account_id = ${accountId}`);
    }

    if (contactId) {
      conditions.push(sql`t.contact_id = ${contactId}`);
    }

    if (contactType) {
      conditions.push(sql`t.contact_type = ${contactType}`);
    }

    conditions.push(
      sql`t.transaction_date >= ${new Date(startDate).toISOString()}`,
    );
    conditions.push(
      sql`t.transaction_date <= ${new Date(endDate).toISOString()}`,
    );

    if (orgId) {
      conditions.push(sql`t.org_id = ${orgId}`);
    }
    const whereClause = sql.join(conditions, sql` AND `);

    const query = sql`
      SELECT 
        t.transaction_date as "date",
        t.description as "details",
        t.transaction_type as "type",
        t.reference_number as "reference",
        t.debit as "debit",
        t.credit as "credit",
        t.source_id as "sourceId",
        t.source_type as "sourceType"
      FROM account_transactions t
      WHERE ${whereClause}
      ORDER BY t.transaction_date ASC
    `;

    const result = await db.execute(query);
    const rows = result as any[];

    let runningBalance = 0;
    const transactions = rows.map((r: any) => {
      const debit = Number(r.debit || 0);
      const credit = Number(r.credit || 0);
      runningBalance += debit - credit;
      return {
        ...r,
        debit,
        credit,
        runningBalance,
      };
    });

    return {
      accountId,
      period: { startDate, endDate },
      transactions,
    };
  }

  async getTrialBalanceReport(
    startDate: string,
    endDate: string,
    orgId?: string,
  ) {
    const conditions: any[] = [];
    if (endDate) {
      conditions.push(
        sql`t.transaction_date <= ${new Date(endDate).toISOString()}`,
      );
    }
    if (orgId) {
      conditions.push(sql`t.org_id = ${orgId}`);
    }

    const whereClause =
      conditions.length > 0 ? sql.join(conditions, sql` AND `) : sql`1=1`;

    const query = sql`
      SELECT 
        COALESCE(a.user_account_name, a.system_account_name) as "accountName",
        a.id as "accountId",
        SUM(t.debit) as "totalDebit",
        SUM(t.credit) as "totalCredit"
      FROM account_transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE ${whereClause}
      GROUP BY COALESCE(a.user_account_name, a.system_account_name), a.id
      HAVING SUM(t.debit) != SUM(t.credit)
    `;

    const result = await db.execute(query);
    const rows = result as any[];

    let totalDebit = 0;
    let totalCredit = 0;

    const accountsData = rows
      .map((r: any) => {
        const debit = Number(r.totalDebit || 0);
        const credit = Number(r.totalCredit || 0);

        const netDebit = debit > credit ? debit - credit : 0;
        const netCredit = credit > debit ? credit - debit : 0;

        totalDebit += netDebit;
        totalCredit += netCredit;

        return {
          accountId: r.accountId,
          accountName: r.accountName,
          debit: netDebit,
          credit: netCredit,
        };
      })
      .filter((acc) => acc.debit > 0 || acc.credit > 0);

    return {
      period: { startDate, endDate },
      accounts: accountsData,
      totalDebit,
      totalCredit,
    };
  }

  async getSalesByCustomerReport(
    startDate: string,
    endDate: string,
    orgId?: string,
  ) {
    const conditions: any[] = [];
    if (startDate) {
      conditions.push(sql`s.sale_date >= ${new Date(startDate).toISOString()}`);
    }
    if (endDate) {
      conditions.push(sql`s.sale_date <= ${new Date(endDate).toISOString()}`);
    }
    // Assume posted invoices
    conditions.push(sql`s.document_type = 'invoice'`);
    // 'status' goes by what front-end considers "posted" (e.g. Sent, Paid, Posted etc. But for robustness, let's just use NOT Draft and NOT cancelled, or just skip filtering for mockup if we don't have standard statuses yet). Here let's just make sure it's an invoice.

    if (orgId) {
      conditions.push(sql`c.org_id = ${orgId}`);
    }

    const whereClause =
      conditions.length > 0 ? sql.join(conditions, sql` AND `) : sql`1=1`;

    const query = sql`
      SELECT 
        c.id as "customerId",
        c.display_name as "customerName",
        COUNT(s.id) as "invoiceCount",
        SUM(s.total) as "totalSales"
      FROM sales_orders s
      JOIN customers c ON s.customer_id = c.id
      WHERE ${whereClause}
      GROUP BY c.id, c.display_name
      ORDER BY "totalSales" DESC
    `;

    const result = await db.execute(query);
    const rows = result as any[];

    return {
      period: { startDate, endDate },
      data: rows.map((r: any) => ({
        customerId: r.customerId,
        customerName: r.customerName,
        invoiceCount: Number(r.invoiceCount || 0),
        totalSales: Number(r.totalSales || 0),
      })),
    };
  }

  async getInventoryValuationReport(_orgId?: string) {
    const conditions: any[] = [];
    // If you need to filter outlet inventory by orgId in the future, you could join an outlet or org table here.
    // For now, no strict orgId filter to keep it simple, or filter on createdBy if added.
    const whereClause =
      conditions.length > 0 ? sql.join(conditions, sql` AND `) : sql`1=1`;

    const query = sql`
      SELECT 
        p.product_name as "itemName",
        p.sku as "sku",
        s.location_name as "warehouse",
        COALESCE(SUM(i.current_stock), 0) as "stockOnHand",
        (COALESCE(SUM(i.current_stock), 0) * COALESCE(p.cost_price, 0)) as "assetValue"
      FROM outlet_inventory i
      JOIN products p ON i.product_id = p.id
      LEFT JOIN storage_locations s ON p.storage_id = s.id
      WHERE ${whereClause}
      GROUP BY p.id, p.product_name, p.sku, s.location_name, p.cost_price
      HAVING SUM(i.current_stock) > 0
      ORDER BY "assetValue" DESC
    `;

    const result = await db.execute(query);
    const rows = result as any[];

    return {
      data: rows.map((r: any) => ({
        itemName: r.itemName,
        sku: r.sku || "--",
        warehouse: r.warehouse || "Default",
        stockOnHand: Number(r.stockOnHand || 0),
        assetValue: Number(r.assetValue || 0),
      })),
    };
  }

  // --- Transaction Locking ---

  async findTransactionLocks(orgId?: string) {
    const resolvedOrgId = orgId || this.defaultOrgId;
    const locks = await db
      .select()
      .from(transactionLocks)
      .where(eq(transactionLocks.orgId, resolvedOrgId));

    return locks.map((l) => ({
      moduleName: l.moduleName,
      lockDate: l.lockDate,
      reason: l.reason,
      updatedAt: l.updatedAt,
    }));
  }

  async lockModule(
    data: { moduleName: string; lockDate: string; reason: string },
    orgId?: string,
  ) {
    const resolvedOrgId = orgId || this.defaultOrgId;

    const existing = await db
      .select()
      .from(transactionLocks)
      .where(
        and(
          eq(transactionLocks.orgId, resolvedOrgId),
          eq(transactionLocks.moduleName, data.moduleName),
        ),
      );

    if (existing.length > 0) {
      // Update existing lock
      const [updated] = await db
        .update(transactionLocks)
        .set({
          lockDate: new Date(data.lockDate),
          reason: data.reason,
          updatedAt: new Date(),
        })
        .where(
          and(
            eq(transactionLocks.orgId, resolvedOrgId),
            eq(transactionLocks.moduleName, data.moduleName),
          ),
        )
        .returning();
      return updated;
    }

    const [created] = await db
      .insert(transactionLocks)
      .values({
        orgId: resolvedOrgId,
        moduleName: data.moduleName,
        lockDate: new Date(data.lockDate),
        reason: data.reason,
      })
      .returning();
    return created;
  }

  async unlockModule(moduleName: string, orgId?: string) {
    const resolvedOrgId = orgId || this.defaultOrgId;
    await db
      .delete(transactionLocks)
      .where(
        and(
          eq(transactionLocks.orgId, resolvedOrgId),
          eq(transactionLocks.moduleName, moduleName),
        ),
      );
    return { success: true };
  }
}
