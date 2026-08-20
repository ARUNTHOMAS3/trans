import { Injectable, HttpException, HttpStatus } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { v4 as uuidv4 } from "uuid";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { client } from "../../../../db/db";

@Injectable()
export class PaymentsMadeService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private isUuid(val: string): boolean {
    return /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(val);
  }

  async createPayment(tenant: TenantContext, dto: any) {
    const id = uuidv4();
    let paymentNumber = dto.paymentNumber || dto.payment_number || `PM-${Date.now()}`;

    const existingPayment = await client.unsafe(
      `SELECT payment_number FROM payment_made_master WHERE payment_number = $1 LIMIT 1`,
      [paymentNumber],
    );

    if (existingPayment[0]) {
      paymentNumber = `${paymentNumber}-${Date.now().toString().slice(-4)}`;
    }

    let paidThroughAccountId = null;
    const incomingPaidThrough = dto.paidThroughAccountId || dto.paid_through_account_id;
    if (incomingPaidThrough) {
      if (this.isUuid(incomingPaidThrough)) {
        paidThroughAccountId = incomingPaidThrough;
      } else {
        const accountRow = await client.unsafe(
          `SELECT id FROM accounts WHERE system_account_name = $1 OR user_account_name = $1 LIMIT 1`,
          [incomingPaidThrough],
        );
        if (accountRow[0]) {
          paidThroughAccountId = accountRow[0].id;
        }
      }
    }

    let depositToAccountId = null;
    const incomingDepositTo = dto.depositToAccountId || dto.deposit_to_account_id;
    if (incomingDepositTo) {
      if (this.isUuid(incomingDepositTo)) {
        depositToAccountId = incomingDepositTo;
      } else {
        const accountRow = await client.unsafe(
          `SELECT id FROM accounts WHERE system_account_name = $1 OR user_account_name = $1 LIMIT 1`,
          [incomingDepositTo],
        );
        if (accountRow[0]) {
          depositToAccountId = accountRow[0].id;
        }
      }
    }

    const payload = {
      id,
      entity_id: tenant.entityId,
      vendor_id: dto.vendorId || dto.vendor_id,
      payment_type: dto.paymentType || dto.payment_type || 'RECORD_PAYMENT',
      transaction_series_id: dto.transactionSeriesId && this.isUuid(dto.transactionSeriesId) ? dto.transactionSeriesId : null,
      payment_number: paymentNumber,
      payment_date: dto.paymentDate || dto.payment_date || new Date().toISOString().split('T')[0],
      payment_amount: dto.paymentAmount || dto.payment_amount || dto.amount || "0",
      currency_id: dto.currencyId && this.isUuid(dto.currencyId) ? dto.currencyId : null,
      exchange_rate: dto.exchangeRate || dto.exchange_rate || "1.0",
      paid_through_account_id: paidThroughAccountId,
      deposit_to_account_id: depositToAccountId,
      payment_mode: dto.paymentMode || dto.payment_mode || "Cash",
      reference_number: dto.referenceNumber || dto.reference_number || null,
      status: dto.status || "draft",
      notes: dto.notes || null,
      total_allocated: dto.totalAllocated || dto.total_allocated || "0",
      total_refunded: dto.totalRefunded || dto.total_refunded || "0",
      excess_amount: dto.excessAmount || dto.excess_amount || dto.unusedAmount || dto.unused_amount || "0",
    };

    const keys = Object.keys(payload);
    const cols = keys.map((k) => `"${k}"`).join(", ");
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");
    const values: any[] = Object.values(payload);

    let data: any;
    try {
      const rows = await client.unsafe(
        `INSERT INTO payment_made_master (${cols}) VALUES (${placeholders}) RETURNING *`,
        values,
      );
      data = rows[0];
    } catch (error: any) {
      throw new HttpException(
        `Failed to create payment made: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }

    const allocations = dto.billAllocations || dto.bill_allocations;
    if (Array.isArray(allocations) && allocations.length > 0) {
      for (const item of allocations) {
        await client.unsafe(
          `INSERT INTO payment_made_bill_allocations (id, payment_made_id, bill_id, bill_amount, amount_due, allocated_amount, payment_date, remarks)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [
            item.id || uuidv4(),
            id,
            item.billId || item.bill_id,
            item.billAmount || item.bill_amount || "0",
            item.amountDue || item.amount_due || "0",
            item.allocatedAmount || item.allocated_amount || item.amount || "0",
            item.paymentDate || item.payment_date || dto.paymentDate || dto.payment_date || new Date().toISOString().split('T')[0],
            item.remarks || null,
          ],
        );
      }
    }

    const taxData = dto.paymentMadeTax || dto.payment_made_tax;
    if (taxData) {
      await client.unsafe(
        `INSERT INTO payment_made_tax (id, payment_made_id, gst_treatment, gstin, source_of_supply, destination_of_supply, description_of_supply, reverse_charge, tds_tax_id, tds_percentage, tds_amount)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
        [
          uuidv4(),
          id,
          taxData.gst_treatment || taxData.gstTreatment || null,
          taxData.gstin || null,
          taxData.source_of_supply || taxData.sourceOfSupply || null,
          taxData.destination_of_supply || taxData.destinationOfSupply || null,
          taxData.description_of_supply || taxData.descriptionOfSupply || null,
          !!(taxData.reverse_charge || taxData.reverseCharge),
          (taxData.tds_tax_id || taxData.tdsTaxId) && this.isUuid(String(taxData.tds_tax_id || taxData.tdsTaxId)) ? String(taxData.tds_tax_id || taxData.tdsTaxId) : null,
          taxData.tds_percentage || taxData.tdsPercentage || 0,
          taxData.tds_amount || taxData.tdsAmount || 0,
        ],
      );
    }

    const attachments = dto.paymentMadeAttachments || dto.payment_made_attachments;
    if (Array.isArray(attachments) && attachments.length > 0) {
      for (const item of attachments) {
        await client.unsafe(
          `INSERT INTO payment_made_attachments (id, payment_made_id, file_name, file_path, original_file_name, file_size, file_type, remarks)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [
            item.id || uuidv4(),
            id,
            item.file_name || item.fileName,
            item.file_path || item.filePath,
            item.original_file_name || item.originalFileName || item.file_name || item.fileName,
            item.file_size || item.fileSize || null,
            item.file_type || item.fileType || null,
            item.remarks || null,
          ],
        );
      }
    }

    await this.postJournalEntries(tenant, data, dto);

    return { data };
  }

  async findAll(
    tenant: TenantContext,
    page: number,
    limit: number,
    search?: string,
    status?: string,
    vendorId?: string,
  ) {
    const offset = (page - 1) * limit;

    let sqlQuery = `SELECT * FROM payment_made_master WHERE entity_id = $1`;
    const params: any[] = [tenant.entityId];

    if (vendorId) {
      params.push(vendorId);
      sqlQuery += ` AND vendor_id = $${params.length}`;
    }

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      const sIdx = params.length;
      sqlQuery += ` AND (payment_number ILIKE $${sIdx} OR reference_number ILIKE $${sIdx})`;
    }

    sqlQuery += ` ORDER BY payment_date DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    const data = await client.unsafe(sqlQuery, [...params, limit, offset]);

    for (const p of data ?? []) {
      const [attachments, taxRows, vendors] = await Promise.all([
        client.unsafe(`SELECT * FROM payment_made_attachments WHERE payment_made_id = $1`, [p.id]),
        client.unsafe(`SELECT * FROM payment_made_tax WHERE payment_made_id = $1`, [p.id]),
        p.vendor_id
          ? client.unsafe(`SELECT * FROM vendors WHERE id = $1 LIMIT 1`, [p.vendor_id])
          : Promise.resolve([]),
      ]);
      p.payment_made_attachments = attachments ?? [];
      p.payment_made_tax = taxRows ?? [];
      p.vendors = vendors[0] ?? null;
    }

    return { data };
  }

  async findOne(id: string, tenant: TenantContext) {
    const rows = await client.unsafe(
      `SELECT * FROM payment_made_master WHERE id = $1 AND entity_id = $2 LIMIT 1`,
      [id, tenant.entityId],
    );

    const data = rows[0];
    if (!data) {
      throw new HttpException(`Failed to fetch payment`, HttpStatus.NOT_FOUND);
    }

    const [attachments, taxRows] = await Promise.all([
      client.unsafe(`SELECT * FROM payment_made_attachments WHERE payment_made_id = $1`, [id]),
      client.unsafe(`SELECT * FROM payment_made_tax WHERE payment_made_id = $1`, [id]),
    ]);

    data.payment_made_attachments = attachments ?? [];
    data.payment_made_tax = taxRows ?? [];

    return { data };
  }

  async updatePayment(id: string, tenant: TenantContext, dto: any) {
    let paidThroughAccountId = null;
    const incomingPaidThrough = dto.paidThroughAccountId || dto.paid_through_account_id;
    if (incomingPaidThrough) {
      if (this.isUuid(incomingPaidThrough)) {
        paidThroughAccountId = incomingPaidThrough;
      } else {
        const accountRow = await client.unsafe(
          `SELECT id FROM accounts WHERE system_account_name = $1 OR user_account_name = $1 LIMIT 1`,
          [incomingPaidThrough],
        );
        if (accountRow[0]) {
          paidThroughAccountId = accountRow[0].id;
        }
      }
    }

    let depositToAccountId = null;
    const incomingDepositTo = dto.depositToAccountId || dto.deposit_to_account_id;
    if (incomingDepositTo) {
      if (this.isUuid(incomingDepositTo)) {
        depositToAccountId = incomingDepositTo;
      } else {
        const accountRow = await client.unsafe(
          `SELECT id FROM accounts WHERE system_account_name = $1 OR user_account_name = $1 LIMIT 1`,
          [incomingDepositTo],
        );
        if (accountRow[0]) {
          depositToAccountId = accountRow[0].id;
        }
      }
    }

    const updatePayload = {
      vendor_id: dto.vendorId || dto.vendor_id,
      payment_type: dto.paymentType || dto.payment_type,
      transaction_series_id: dto.transactionSeriesId && this.isUuid(dto.transactionSeriesId) ? dto.transactionSeriesId : null,
      payment_number: dto.paymentNumber || dto.payment_number,
      payment_date: dto.paymentDate || dto.payment_date,
      payment_amount: dto.paymentAmount || dto.payment_amount || dto.amount,
      currency_id: dto.currencyId && this.isUuid(dto.currencyId) ? dto.currencyId : null,
      exchange_rate: dto.exchangeRate || dto.exchange_rate,
      paid_through_account_id: paidThroughAccountId,
      deposit_to_account_id: depositToAccountId,
      payment_mode: dto.paymentMode || dto.payment_mode,
      reference_number: dto.referenceNumber || dto.reference_number,
      status: dto.status,
      notes: dto.notes,
      total_allocated: dto.totalAllocated || dto.total_allocated,
      total_refunded: dto.totalRefunded || dto.total_refunded,
      excess_amount: dto.excessAmount || dto.excess_amount || dto.unusedAmount || dto.unused_amount,
    };

    const keys = Object.keys(updatePayload);
    const setClauses = keys.map((k, i) => `"${k}" = $${i + 1}`).join(", ");
    const values: any[] = Object.values(updatePayload);

    let data: any;
    try {
      const rows = await client.unsafe(
        `UPDATE payment_made_master SET ${setClauses} WHERE id = $${keys.length + 1} AND entity_id = $${keys.length + 2} RETURNING *`,
        [...values, id, tenant.entityId],
      );
      data = rows[0];
    } catch (error: any) {
      throw new HttpException(
        `Failed to update payment: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }

    const allocations = dto.billAllocations || dto.bill_allocations;
    if (allocations) {
      await client.unsafe(
        `DELETE FROM payment_made_bill_allocations WHERE payment_made_id = $1`,
        [id],
      );

      if (Array.isArray(allocations) && allocations.length > 0) {
        for (const item of allocations) {
          await client.unsafe(
            `INSERT INTO payment_made_bill_allocations (id, payment_made_id, bill_id, bill_amount, amount_due, allocated_amount, payment_date, remarks)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
            [
              item.id || uuidv4(),
              id,
              item.billId || item.bill_id,
              item.billAmount || item.bill_amount || "0",
              item.amountDue || item.amount_due || "0",
              item.allocatedAmount || item.allocated_amount || item.amount || "0",
              item.paymentDate || item.payment_date || dto.paymentDate || dto.payment_date || new Date().toISOString().split('T')[0],
              item.remarks || null,
            ],
          );
        }
      }
    }

    const taxData = dto.paymentMadeTax || dto.payment_made_tax;
    if (taxData !== undefined) {
      await client.unsafe(
        `DELETE FROM payment_made_tax WHERE payment_made_id = $1`,
        [id],
      );

      if (taxData) {
        await client.unsafe(
          `INSERT INTO payment_made_tax (id, payment_made_id, gst_treatment, gstin, source_of_supply, destination_of_supply, description_of_supply, reverse_charge, tds_tax_id, tds_percentage, tds_amount)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
          [
            uuidv4(),
            id,
            taxData.gst_treatment || taxData.gstTreatment || null,
            taxData.gstin || null,
            taxData.source_of_supply || taxData.sourceOfSupply || null,
            taxData.destination_of_supply || taxData.destinationOfSupply || null,
            taxData.description_of_supply || taxData.descriptionOfSupply || null,
            !!(taxData.reverse_charge || taxData.reverseCharge),
            (taxData.tds_tax_id || taxData.tdsTaxId) && this.isUuid(String(taxData.tds_tax_id || taxData.tdsTaxId)) ? String(taxData.tds_tax_id || taxData.tdsTaxId) : null,
            taxData.tds_percentage || taxData.tdsPercentage || 0,
            taxData.tds_amount || taxData.tdsAmount || 0,
          ],
        );
      }
    }

    const attachments = dto.paymentMadeAttachments || dto.payment_made_attachments;
    if (attachments !== undefined) {
      await client.unsafe(
        `DELETE FROM payment_made_attachments WHERE payment_made_id = $1`,
        [id],
      );

      if (Array.isArray(attachments) && attachments.length > 0) {
        for (const item of attachments) {
          await client.unsafe(
            `INSERT INTO payment_made_attachments (id, payment_made_id, file_name, file_path, original_file_name, file_size, file_type, remarks)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
            [
              item.id || uuidv4(),
              id,
              item.file_name || item.fileName,
              item.file_path || item.filePath,
              item.original_file_name || item.originalFileName || item.file_name || item.fileName,
              item.file_size || item.fileSize || null,
              item.file_type || item.fileType || null,
              item.remarks || null,
            ],
          );
        }
      }
    }

    await this.postJournalEntries(tenant, data, dto);

    return { data };
  }

  async remove(id: string, tenant: TenantContext) {
    const existingJes = await client.unsafe(
      `SELECT id FROM journal_entries WHERE entity_id = $1 AND source_document_type = 'PAYMENT_MADE' AND source_document_id = $2`,
      [tenant.entityId, id],
    );

    if (existingJes && existingJes.length > 0) {
      const jeIds = existingJes.map((j: any) => j.id);
      await client.unsafe(`DELETE FROM journal_entry_lines WHERE journal_entry_id = ANY($1)`, [jeIds]);
      await client.unsafe(`DELETE FROM journal_entries WHERE id = ANY($1)`, [jeIds]);
    }

    try {
      await client.unsafe(
        `DELETE FROM payment_made_master WHERE id = $1 AND entity_id = $2`,
        [id, tenant.entityId],
      );
    } catch (error: any) {
      throw new HttpException(
        `Failed to delete payment: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }

    return { success: true };
  }

  async getSettings(tenant: TenantContext) {
    return {
      data: {
        autoGenerate: true,
        prefix: "PM-",
        nextNumber: "00098",
      },
    };
  }

  async getNextNumber(tenant: TenantContext) {
    return {
      data: {
        formatted: "PM-00098",
      },
    };
  }

  private async postJournalEntries(tenant: TenantContext, paymentData: any, dto: any) {
    if (!paymentData || !paymentData.id) return;

    const paymentId = paymentData.id;
    const status = (paymentData.status || dto.status || "draft").toString().toLowerCase();

    if (status === "draft") {
      const existingJE = await client.unsafe(
        `SELECT id FROM journal_entries WHERE entity_id = $1 AND source_document_type = 'PAYMENT_MADE' AND source_document_id = $2 LIMIT 1`,
        [tenant.entityId, paymentId],
      );

      if (existingJE[0]?.id) {
        await client.unsafe(`DELETE FROM journal_entry_lines WHERE journal_entry_id = $1`, [existingJE[0].id]);
        await client.unsafe(`DELETE FROM journal_entries WHERE id = $1`, [existingJE[0].id]);
        try {
          await client.unsafe(`UPDATE payment_made_master SET journal_entry_id = NULL WHERE id = $1`, [paymentId]);
        } catch (_) {}
      }
      return;
    }

    let accountsPayableAccountId: string | null = null;
    const apSysRow = await client.unsafe(
      `SELECT id FROM accounts WHERE system_account_name = 'Accounts Payable' LIMIT 1`,
    );

    if (apSysRow[0]) {
      accountsPayableAccountId = apSysRow[0].id;
    } else {
      const apUserRow = await client.unsafe(
        `SELECT id FROM accounts WHERE user_account_name = 'Accounts Payable' OR account_type = 'Accounts Payable' LIMIT 1`,
      );
      if (apUserRow[0]) {
        accountsPayableAccountId = apUserRow[0].id;
      }
    }

    if (!accountsPayableAccountId) {
      console.warn("No valid account ID found in accounts table for Accounts Payable");
      return;
    }

    let prepaidExpensesAccountId: string | null = null;
    const prepaidSysRow = await client.unsafe(
      `SELECT id FROM accounts WHERE system_account_name = 'Prepaid Expenses' LIMIT 1`,
    );

    if (prepaidSysRow[0]) {
      prepaidExpensesAccountId = prepaidSysRow[0].id;
    } else {
      const prepaidUserRow = await client.unsafe(
        `SELECT id FROM accounts WHERE user_account_name = 'Prepaid Expenses' OR account_type = 'Other Current Asset' LIMIT 1`,
      );
      prepaidExpensesAccountId = prepaidUserRow[0]?.id || accountsPayableAccountId;
    }

    let paidThroughAccountId: string | null = paymentData.paid_through_account_id || null;
    if (!paidThroughAccountId) {
      const incomingPaidThrough = dto.paidThroughAccountId || dto.paid_through_account_id || "Petty Cash";
      if (this.isUuid(incomingPaidThrough)) {
        paidThroughAccountId = incomingPaidThrough;
      } else {
        const accountRow = await client.unsafe(
          `SELECT id FROM accounts WHERE system_account_name = $1 OR user_account_name = $1 LIMIT 1`,
          [incomingPaidThrough],
        );
        if (accountRow[0]) {
          paidThroughAccountId = accountRow[0].id;
        }
      }
    }

    if (paidThroughAccountId) {
      const verifyRow = await client.unsafe(
        `SELECT id FROM accounts WHERE id = $1 LIMIT 1`,
        [paidThroughAccountId],
      );
      if (!verifyRow[0]) {
        paidThroughAccountId = null;
      }
    }

    if (!paidThroughAccountId) {
      const cashFallback = await client.unsafe(
        `SELECT id FROM accounts WHERE system_account_name = 'Petty Cash' OR user_account_name = 'Petty Cash' OR account_type = 'Cash' LIMIT 1`,
      );
      paidThroughAccountId = cashFallback[0]?.id || accountsPayableAccountId;
    }

    const paymentAmount = parseFloat(paymentData.payment_amount?.toString() || dto.paymentAmount?.toString() || dto.amount?.toString() || "0");
    const paymentDate = paymentData.payment_date || dto.paymentDate || dto.payment_date || new Date().toISOString().split("T")[0];
    const paymentNumber = paymentData.payment_number || dto.paymentNumber || dto.payment_number || `PM-${Date.now()}`;
    const vendorId = paymentData.vendor_id || dto.vendorId || dto.vendor_id || null;

    const existingJE = await client.unsafe(
      `SELECT id, created_by FROM journal_entries WHERE entity_id = $1 AND source_document_type = 'PAYMENT_MADE' AND source_document_id = $2 LIMIT 1`,
      [tenant.entityId, paymentId],
    );

    const journalEntryId = existingJE[0]?.id || uuidv4();

    if (existingJE[0]?.id) {
      await client.unsafe(`DELETE FROM journal_entry_lines WHERE journal_entry_id = $1`, [existingJE[0].id]);
    }

    let currentUserId: string | null = null;
    if (tenant.userId && this.isUuid(tenant.userId)) {
      currentUserId = tenant.userId;
    } else {
      const incomingUser = dto.created_by || dto.createdBy || dto.updated_by || dto.updatedBy;
      if (incomingUser && this.isUuid(String(incomingUser))) {
        currentUserId = String(incomingUser);
      } else {
        const firstUser = await client.unsafe(`SELECT id FROM users LIMIT 1`);
        if (firstUser[0]) {
          currentUserId = firstUser[0].id;
        }
      }
    }

    const defaultOrgId = "00000000-0000-0000-0000-000000000000";

    if (existingJE[0]?.id) {
      await client.unsafe(
        `UPDATE journal_entries SET
           org_id = $1, entity_id = $2, journal_number = $3, journal_type = 'payment made',
           journal_date = $4, posting_date = $4, reference_number = $5, narration = $6,
           source_module = 'purchase', source_document_type = 'PAYMENT_MADE', source_document_id = $7,
           currency_code = $8, exchange_rate = $9, status = 'POSTED', updated_by = $10
         WHERE id = $11`,
        [
          tenant.orgId || defaultOrgId,
          tenant.entityId,
          paymentNumber,
          paymentDate,
          paymentNumber,
          paymentData.notes || dto.notes || `Payment Made ${paymentNumber}`,
          paymentId,
          paymentData.currency_code || dto.currencyCode || "INR",
          parseFloat(paymentData.exchange_rate?.toString() || dto.exchangeRate?.toString() || "1.0"),
          currentUserId,
          journalEntryId,
        ],
      );
    } else {
      await client.unsafe(
        `INSERT INTO journal_entries (id, org_id, entity_id, fiscal_year_id, journal_number, journal_type, journal_date, posting_date, reference_number, narration, source_module, source_document_type, source_document_id, currency_code, exchange_rate, status, created_by, updated_by)
         VALUES ($1, $2, $3, null, $4, 'payment made', $5, $5, $6, $7, 'purchase', 'PAYMENT_MADE', $8, $9, $10, 'POSTED', $11, $11)`,
        [
          journalEntryId,
          tenant.orgId || defaultOrgId,
          tenant.entityId,
          paymentNumber,
          paymentDate,
          paymentNumber,
          paymentData.notes || dto.notes || `Payment Made ${paymentNumber}`,
          paymentId,
          paymentData.currency_code || dto.currencyCode || "INR",
          parseFloat(paymentData.exchange_rate?.toString() || dto.exchangeRate?.toString() || "1.0"),
          existingJE[0]?.created_by || currentUserId,
        ],
      );
    }

    if (paymentAmount > 0) {
      const lines: any[] = [
        {
          id: uuidv4(),
          journal_entry_id: journalEntryId,
          account_id: paidThroughAccountId,
          transaction_date: paymentDate,
          reference_number: paymentNumber,
          description: "Payment Made - Paid Through",
          debit: 0,
          credit: paymentAmount,
          source_id: paymentId,
          source_type: "PAYMENT_MADE",
          contact_id: vendorId,
          contact_type: "vendor",
          entity_id: tenant.entityId,
          org_id: tenant.orgId || defaultOrgId,
          line_number: null,
        },
        {
          id: uuidv4(),
          journal_entry_id: journalEntryId,
          account_id: prepaidExpensesAccountId,
          transaction_date: paymentDate,
          reference_number: paymentNumber,
          description: "Payment Made - Prepaid Expenses",
          debit: paymentAmount,
          credit: 0,
          source_id: paymentId,
          source_type: "PAYMENT_MADE",
          contact_id: vendorId,
          contact_type: "vendor",
          entity_id: tenant.entityId,
          org_id: tenant.orgId || defaultOrgId,
          line_number: null,
        },
      ];

      const dbAllocations = await client.unsafe(
        `SELECT pmba.*, b.bill_number FROM payment_made_bill_allocations pmba
         LEFT JOIN bills b ON b.id = pmba.bill_id
         WHERE pmba.payment_made_id = $1`,
        [paymentId],
      );

      const allocationsList = (dbAllocations && dbAllocations.length > 0)
        ? dbAllocations
        : (dto.billAllocations || dto.bill_allocations || []);

      for (const alloc of allocationsList) {
        const allocatedAmt = parseFloat(alloc.allocated_amount?.toString() || alloc.allocatedAmount?.toString() || alloc.amount?.toString() || "0");
        const billNumber = alloc.bill_number || alloc.billNumber || paymentNumber;

        if (allocatedAmt > 0) {
          lines.push({
            id: uuidv4(),
            journal_entry_id: journalEntryId,
            account_id: accountsPayableAccountId,
            transaction_date: paymentDate,
            reference_number: billNumber,
            description: `Bill allocation - ${billNumber}`,
            debit: allocatedAmt,
            credit: 0,
            source_id: paymentId,
            source_type: "PAYMENT_MADE",
            contact_id: vendorId,
            contact_type: "vendor",
            entity_id: tenant.entityId,
            org_id: tenant.orgId || defaultOrgId,
            line_number: null,
          });

          lines.push({
            id: uuidv4(),
            journal_entry_id: journalEntryId,
            account_id: prepaidExpensesAccountId,
            transaction_date: paymentDate,
            reference_number: billNumber,
            description: `Bill allocation - ${billNumber}`,
            debit: 0,
            credit: allocatedAmt,
            source_id: paymentId,
            source_type: "PAYMENT_MADE",
            contact_id: vendorId,
            contact_type: "vendor",
            entity_id: tenant.entityId,
            org_id: tenant.orgId || defaultOrgId,
            line_number: null,
          });
        }
      }

      for (const line of lines) {
        await client.unsafe(
          `INSERT INTO journal_entry_lines (id, journal_entry_id, account_id, transaction_date, reference_number, description, debit, credit, source_id, source_type, contact_id, contact_type, entity_id, org_id, line_number)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)`,
          [
            line.id,
            line.journal_entry_id,
            line.account_id,
            line.transaction_date,
            line.reference_number,
            line.description,
            line.debit,
            line.credit,
            line.source_id,
            line.source_type,
            line.contact_id,
            line.contact_type,
            line.entity_id,
            line.org_id,
            line.line_number,
          ],
        );
      }
    }

    try {
      await client.unsafe(
        `UPDATE payment_made_master SET journal_entry_id = $1 WHERE id = $2`,
        [journalEntryId, paymentId],
      );
    } catch (_) {}
  }
}
