import { Injectable, HttpException, HttpStatus } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { v4 as uuidv4 } from "uuid";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";

@Injectable()
export class PaymentsMadeService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private isUuid(val: string): boolean {
    return /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(val);
  }

  async createPayment(tenant: TenantContext, dto: any) {
    const supabase = this.supabaseService.getClient();
    const id = uuidv4();

    let paymentNumber = dto.paymentNumber || dto.payment_number || `PM-${Date.now()}`;
    
    // Check if the payment number already exists to satisfy UNIQUE constraint
    const { data: existingPayment } = await supabase
      .from("payment_made_master")
      .select("payment_number")
      .eq("payment_number", paymentNumber)
      .maybeSingle();

    if (existingPayment) {
      paymentNumber = `${paymentNumber}-${Date.now().toString().slice(-4)}`;
    }

    // Resolve paidThroughAccountId
    let paidThroughAccountId = null;
    const incomingPaidThrough = dto.paidThroughAccountId || dto.paid_through_account_id;
    if (incomingPaidThrough) {
      if (this.isUuid(incomingPaidThrough)) {
        paidThroughAccountId = incomingPaidThrough;
      } else {
        const { data: accountRow } = await supabase
          .from("accounts")
          .select("id")
          .or(`system_account_name.eq.${incomingPaidThrough},user_account_name.eq.${incomingPaidThrough}`)
          .maybeSingle();
        if (accountRow) {
          paidThroughAccountId = accountRow.id;
        }
      }
    }

    // Resolve depositToAccountId
    let depositToAccountId = null;
    const incomingDepositTo = dto.depositToAccountId || dto.deposit_to_account_id;
    if (incomingDepositTo) {
      if (this.isUuid(incomingDepositTo)) {
        depositToAccountId = incomingDepositTo;
      } else {
        const { data: accountRow } = await supabase
          .from("accounts")
          .select("id")
          .or(`system_account_name.eq.${incomingDepositTo},user_account_name.eq.${incomingDepositTo}`)
          .maybeSingle();
        if (accountRow) {
          depositToAccountId = accountRow.id;
        }
      }
    }

    const { data, error } = await supabase
      .from("payment_made_master")
      .insert({
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
      })
      .select()
      .single();

    if (error) {
      throw new HttpException(
        `Failed to create payment made: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }

    const allocations = dto.billAllocations || dto.bill_allocations;
    if (Array.isArray(allocations) && allocations.length > 0) {
      const recordsToInsert = allocations.map(item => ({
        id: item.id || uuidv4(),
        payment_made_id: id,
        bill_id: item.billId || item.bill_id,
        bill_amount: item.billAmount || item.bill_amount || "0",
        amount_due: item.amountDue || item.amount_due || "0",
        allocated_amount: item.allocatedAmount || item.allocated_amount || item.amount || "0",
        payment_date: item.paymentDate || item.payment_date || dto.paymentDate || dto.payment_date || new Date().toISOString().split('T')[0],
        remarks: item.remarks || null,
      }));

      const { error: allocationError } = await supabase
        .from("payment_made_bill_allocations")
        .insert(recordsToInsert);

      if (allocationError) {
        throw new HttpException(
          `Failed to save bill allocations: ${allocationError.message}`,
          HttpStatus.INTERNAL_SERVER_ERROR,
        );
      }
    }

    const taxData = dto.paymentMadeTax || dto.payment_made_tax;
    if (taxData) {
      const { error: taxError } = await supabase
        .from("payment_made_tax")
        .insert({
          id: uuidv4(),
          payment_made_id: id,
          gst_treatment: taxData.gst_treatment || taxData.gstTreatment || null,
          gstin: taxData.gstin || null,
          source_of_supply: taxData.source_of_supply || taxData.sourceOfSupply || null,
          destination_of_supply: taxData.destination_of_supply || taxData.destinationOfSupply || null,
          description_of_supply: taxData.description_of_supply || taxData.descriptionOfSupply || null,
          reverse_charge: !!(taxData.reverse_charge || taxData.reverseCharge),
          tds_tax_id: (taxData.tds_tax_id || taxData.tdsTaxId) && this.isUuid(String(taxData.tds_tax_id || taxData.tdsTaxId)) ? String(taxData.tds_tax_id || taxData.tdsTaxId) : null,
          tds_percentage: taxData.tds_percentage || taxData.tdsPercentage || 0,
          tds_amount: taxData.tds_amount || taxData.tdsAmount || 0,
        });

      if (taxError) {
        throw new HttpException(
          `Failed to save payment tax info: ${taxError.message}`,
          HttpStatus.INTERNAL_SERVER_ERROR,
        );
      }
    }

    const attachments = dto.paymentMadeAttachments || dto.payment_made_attachments;
    if (Array.isArray(attachments) && attachments.length > 0) {
      const recordsToInsert = attachments.map(item => ({
        id: item.id || uuidv4(),
        payment_made_id: id,
        file_name: item.file_name || item.fileName,
        file_path: item.file_path || item.filePath,
        original_file_name: item.original_file_name || item.originalFileName || item.file_name || item.fileName,
        file_size: item.file_size || item.fileSize || null,
        file_type: item.file_type || item.fileType || null,
        remarks: item.remarks || null,
      }));

      const { error: attachError } = await supabase
        .from("payment_made_attachments")
        .insert(recordsToInsert);

      if (attachError) {
        throw new HttpException(
          `Failed to save payment attachments: ${attachError.message}`,
          HttpStatus.INTERNAL_SERVER_ERROR,
        );
      }
    }

    // Process Journal Entries and Journal Entry Lines according to Payment_made connection docs
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
    const supabase = this.supabaseService.getClient();
    let query = supabase
      .from("payment_made_master")
      .select("*, payment_made_attachments(*), payment_made_tax(*), vendors(*)")
      .eq("entity_id", tenant.entityId);

    if (vendorId) {
      query = query.eq("vendor_id", vendorId);
    }
    if (search) {
      query = query.or(`payment_number.ilike.%${search}%,reference_number.ilike.%${search}%`);
    }

    const { data, error } = await query
      .order("payment_date", { ascending: false })
      .range((page - 1) * limit, page * limit - 1);

    if (error) {
      throw new HttpException(
        `Failed to fetch payments: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
    return { data };
  }

  async findOne(id: string, tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();
    const { data, error } = await supabase
      .from("payment_made_master")
      .select("*, payment_made_attachments(*), payment_made_tax(*)")
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .single();

    if (error) {
      throw new HttpException(
        `Failed to fetch payment: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
    return { data };
  }

  async updatePayment(id: string, tenant: TenantContext, dto: any) {
    const supabase = this.supabaseService.getClient();

    // Resolve paidThroughAccountId
    let paidThroughAccountId = null;
    const incomingPaidThrough = dto.paidThroughAccountId || dto.paid_through_account_id;
    if (incomingPaidThrough) {
      if (this.isUuid(incomingPaidThrough)) {
        paidThroughAccountId = incomingPaidThrough;
      } else {
        const { data: accountRow } = await supabase
          .from("accounts")
          .select("id")
          .or(`system_account_name.eq.${incomingPaidThrough},user_account_name.eq.${incomingPaidThrough}`)
          .maybeSingle();
        if (accountRow) {
          paidThroughAccountId = accountRow.id;
        }
      }
    }

    // Resolve depositToAccountId
    let depositToAccountId = null;
    const incomingDepositTo = dto.depositToAccountId || dto.deposit_to_account_id;
    if (incomingDepositTo) {
      if (this.isUuid(incomingDepositTo)) {
        depositToAccountId = incomingDepositTo;
      } else {
        const { data: accountRow } = await supabase
          .from("accounts")
          .select("id")
          .or(`system_account_name.eq.${incomingDepositTo},user_account_name.eq.${incomingDepositTo}`)
          .maybeSingle();
        if (accountRow) {
          depositToAccountId = accountRow.id;
        }
      }
    }

    const { data, error } = await supabase
      .from("payment_made_master")
      .update({
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
      })
      .eq("id", id)
      .eq("entity_id", tenant.entityId)
      .select()
      .single();

    if (error) {
      throw new HttpException(
        `Failed to update payment: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }

    const allocations = dto.billAllocations || dto.bill_allocations;
    if (allocations) {
      await supabase
        .from("payment_made_bill_allocations")
        .delete()
        .eq("payment_made_id", id);

      if (Array.isArray(allocations) && allocations.length > 0) {
        const recordsToInsert = allocations.map(item => ({
          id: item.id || uuidv4(),
          payment_made_id: id,
          bill_id: item.billId || item.bill_id,
          bill_amount: item.billAmount || item.bill_amount || "0",
          amount_due: item.amountDue || item.amount_due || "0",
          allocated_amount: item.allocatedAmount || item.allocated_amount || item.amount || "0",
          payment_date: item.paymentDate || item.payment_date || dto.paymentDate || dto.payment_date || new Date().toISOString().split('T')[0],
          remarks: item.remarks || null,
        }));

        const { error: allocationError } = await supabase
          .from("payment_made_bill_allocations")
          .insert(recordsToInsert);

        if (allocationError) {
          throw new HttpException(
            `Failed to update bill allocations: ${allocationError.message}`,
            HttpStatus.INTERNAL_SERVER_ERROR,
          );
        }
      }
    }

    const taxData = dto.paymentMadeTax || dto.payment_made_tax;
    if (taxData !== undefined) {
      await supabase
        .from("payment_made_tax")
        .delete()
        .eq("payment_made_id", id);

      if (taxData) {
        const { error: taxError } = await supabase
          .from("payment_made_tax")
          .insert({
            id: uuidv4(),
            payment_made_id: id,
            gst_treatment: taxData.gst_treatment || taxData.gstTreatment || null,
            gstin: taxData.gstin || null,
            source_of_supply: taxData.source_of_supply || taxData.sourceOfSupply || null,
            destination_of_supply: taxData.destination_of_supply || taxData.destinationOfSupply || null,
            description_of_supply: taxData.description_of_supply || taxData.descriptionOfSupply || null,
            reverse_charge: !!(taxData.reverse_charge || taxData.reverseCharge),
            tds_tax_id: (taxData.tds_tax_id || taxData.tdsTaxId) && this.isUuid(String(taxData.tds_tax_id || taxData.tdsTaxId)) ? String(taxData.tds_tax_id || taxData.tdsTaxId) : null,
            tds_percentage: taxData.tds_percentage || taxData.tdsPercentage || 0,
            tds_amount: taxData.tds_amount || taxData.tdsAmount || 0,
          });

        if (taxError) {
          throw new HttpException(
            `Failed to update payment tax info: ${taxError.message}`,
            HttpStatus.INTERNAL_SERVER_ERROR,
          );
        }
      }
    }

    const attachments = dto.paymentMadeAttachments || dto.payment_made_attachments;
    if (attachments !== undefined) {
      await supabase
        .from("payment_made_attachments")
        .delete()
        .eq("payment_made_id", id);

      if (Array.isArray(attachments) && attachments.length > 0) {
        const recordsToInsert = attachments.map(item => ({
          id: item.id || uuidv4(),
          payment_made_id: id,
          file_name: item.file_name || item.fileName,
          file_path: item.file_path || item.filePath,
          original_file_name: item.original_file_name || item.originalFileName || item.file_name || item.fileName,
          file_size: item.file_size || item.fileSize || null,
          file_type: item.file_type || item.fileType || null,
          remarks: item.remarks || null,
        }));

        const { error: attachError } = await supabase
          .from("payment_made_attachments")
          .insert(recordsToInsert);

        if (attachError) {
          throw new HttpException(
            `Failed to update payment attachments: ${attachError.message}`,
            HttpStatus.INTERNAL_SERVER_ERROR,
          );
        }
      }
    }

    // Process Journal Entries and Journal Entry Lines according to Payment_made connection docs
    await this.postJournalEntries(tenant, data, dto);

    return { data };
  }

  async remove(id: string, tenant: TenantContext) {
    const supabase = this.supabaseService.getClient();

    // 1. Delete corresponding journal_entry_lines and journal_entries
    const { data: existingJes } = await supabase
      .from("journal_entries")
      .select("id")
      .eq("entity_id", tenant.entityId)
      .eq("source_document_type", "PAYMENT_MADE")
      .eq("source_document_id", id);

    if (existingJes && existingJes.length > 0) {
      const jeIds = existingJes.map((j: any) => j.id);
      await supabase.from("journal_entry_lines").delete().in("journal_entry_id", jeIds);
      await supabase.from("journal_entries").delete().in("id", jeIds);
    }

    // 2. Delete payment_made_master record
    const { error } = await supabase
      .from("payment_made_master")
      .delete()
      .eq("id", id)
      .eq("entity_id", tenant.entityId);

    if (error) {
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
    const supabase = this.supabaseService.getClient();

    const paymentId = paymentData.id;
    const status = (paymentData.status || dto.status || "draft").toString().toLowerCase();

    // Draft stage: Do not create journal entry or lines
    if (status === "draft") {
      const { data: existingJE } = await supabase
        .from("journal_entries")
        .select("id")
        .eq("entity_id", tenant.entityId)
        .eq("source_document_type", "PAYMENT_MADE")
        .eq("source_document_id", paymentId)
        .maybeSingle();

      if (existingJE?.id) {
        await supabase.from("journal_entry_lines").delete().eq("journal_entry_id", existingJE.id);
        await supabase.from("journal_entries").delete().eq("id", existingJE.id);
        try {
          await supabase.from("payment_made_master").update({ journal_entry_id: null }).eq("id", paymentId);
        } catch (_) {}
      }
      return;
    }

    // Post/Confirm stage: Generate journal_entries and journal_entry_lines

    // 1. Resolve Accounts Payable Account ID
    let accountsPayableAccountId: string | null = null;
    const { data: apAccountRow } = await supabase
      .from("accounts")
      .select("id")
      .or("system_account_name.eq.Accounts Payable,user_account_name.eq.Accounts Payable,account_name.eq.Accounts Payable,account_type.eq.Accounts Payable")
      .limit(1)
      .maybeSingle();

    if (apAccountRow) {
      accountsPayableAccountId = apAccountRow.id;
    } else {
      const { data: apFallback } = await supabase
        .from("accounts")
        .select("id")
        .eq("account_type", "Accounts Payable")
        .limit(1)
        .maybeSingle();
      if (apFallback) {
        accountsPayableAccountId = apFallback.id;
      }
    }

    if (!accountsPayableAccountId) {
      const { data: anyLiability } = await supabase
        .from("accounts")
        .select("id")
        .eq("account_group", "Liabilities")
        .limit(1)
        .maybeSingle();
      accountsPayableAccountId = anyLiability?.id || null;
    }

    if (!accountsPayableAccountId) {
      const { data: anyAccount } = await supabase
        .from("accounts")
        .select("id")
        .limit(1)
        .maybeSingle();
      accountsPayableAccountId = anyAccount?.id || null;
    }

    if (!accountsPayableAccountId) {
      console.warn("No valid account ID found in accounts table for Accounts Payable");
      return;
    }

    // 2. Resolve Paid Through Account ID
    let paidThroughAccountId: string | null = paymentData.paid_through_account_id || null;
    if (!paidThroughAccountId) {
      const incomingPaidThrough = dto.paidThroughAccountId || dto.paid_through_account_id || "Petty Cash";
      if (this.isUuid(incomingPaidThrough)) {
        paidThroughAccountId = incomingPaidThrough;
      } else {
        const { data: accountRow } = await supabase
          .from("accounts")
          .select("id")
          .or(`system_account_name.eq.${incomingPaidThrough},user_account_name.eq.${incomingPaidThrough},account_name.eq.${incomingPaidThrough}`)
          .limit(1)
          .maybeSingle();
        if (accountRow) {
          paidThroughAccountId = accountRow.id;
        }
      }
    }

    // Verify paidThroughAccountId actually exists in accounts table
    if (paidThroughAccountId) {
      const { data: verifyRow } = await supabase
        .from("accounts")
        .select("id")
        .eq("id", paidThroughAccountId)
        .maybeSingle();
      if (!verifyRow) {
        paidThroughAccountId = null;
      }
    }

    if (!paidThroughAccountId) {
      const { data: cashFallback } = await supabase
        .from("accounts")
        .select("id")
        .or("system_account_name.eq.Petty Cash,user_account_name.eq.Petty Cash,account_name.eq.Petty Cash,system_account_name.eq.Cash,user_account_name.eq.Cash,account_type.eq.Cash")
        .limit(1)
        .maybeSingle();
      paidThroughAccountId = cashFallback?.id || accountsPayableAccountId;
    }

    const paymentAmount = parseFloat(paymentData.payment_amount?.toString() || dto.paymentAmount?.toString() || dto.amount?.toString() || "0");
    const paymentDate = paymentData.payment_date || dto.paymentDate || dto.payment_date || new Date().toISOString().split("T")[0];
    const paymentNumber = paymentData.payment_number || dto.paymentNumber || dto.payment_number || `PM-${Date.now()}`;
    const vendorId = paymentData.vendor_id || dto.vendorId || dto.vendor_id || null;

    // 3. Find or Create Header in journal_entries
    const { data: existingJE } = await supabase
      .from("journal_entries")
      .select("id, created_by")
      .eq("entity_id", tenant.entityId)
      .eq("source_document_type", "PAYMENT_MADE")
      .eq("source_document_id", paymentId)
      .maybeSingle();

    const journalEntryId = existingJE?.id || uuidv4();

    if (existingJE?.id) {
      await supabase
        .from("journal_entry_lines")
        .delete()
        .eq("journal_entry_id", existingJE.id);
    }

    // Resolve user UUID from tenant context or fallback to valid user ID from users table
    let currentUserId: string | null = null;
    if (tenant.userId && this.isUuid(tenant.userId)) {
      currentUserId = tenant.userId;
    } else {
      const incomingUser = dto.created_by || dto.createdBy || dto.updated_by || dto.updatedBy;
      if (incomingUser && this.isUuid(String(incomingUser))) {
        currentUserId = String(incomingUser);
      } else {
        const { data: firstUser } = await supabase
          .from("users")
          .select("id")
          .limit(1)
          .maybeSingle();
        if (firstUser) {
          currentUserId = firstUser.id;
        }
      }
    }

    const defaultOrgId = "00000000-0000-0000-0000-000000000000";
    const jeHeader = {
      id: journalEntryId,
      org_id: tenant.orgId || defaultOrgId,
      entity_id: tenant.entityId,
      fiscal_year_id: null,
      journal_number: `JE-${paymentNumber}`,
      journal_type: "PAYMENT_MADE",
      journal_date: paymentDate,
      posting_date: paymentDate,
      reference_number: paymentNumber,
      narration: paymentData.notes || dto.notes || `Payment Made ${paymentNumber}`,
      source_module: "PURCHASES",
      source_document_type: "PAYMENT_MADE",
      source_document_id: paymentId,
      currency_code: paymentData.currency_code || dto.currencyCode || "INR",
      exchange_rate: parseFloat(paymentData.exchange_rate?.toString() || dto.exchangeRate?.toString() || "1.0"),
      status: "POSTED",
      created_by: existingJE?.created_by || currentUserId,
      updated_by: currentUserId,
    };

    if (existingJE?.id) {
      const { error: updateJeErr } = await supabase
        .from("journal_entries")
        .update(jeHeader)
        .eq("id", journalEntryId);
      if (updateJeErr) {
        console.error("Error updating journal_entries:", updateJeErr.message);
      }
    } else {
      const { error: insertJeErr } = await supabase
        .from("journal_entries")
        .insert(jeHeader);
      if (insertJeErr) {
        console.error("Error inserting journal_entries:", insertJeErr.message);
      }
    }

    // 4. Insert double-entry lines into journal_entry_lines
    if (paymentAmount > 0) {
      const lines = [
        // Line 1: Debit Accounts Payable
        {
          id: uuidv4(),
          journal_entry_id: journalEntryId,
          account_id: accountsPayableAccountId,
          transaction_date: paymentDate,
          reference_number: paymentNumber,
          description: "Payment Made to Vendor - Accounts Payable",
          debit: paymentAmount,
          credit: 0,
          source_id: paymentId,
          source_type: "PAYMENT_MADE",
          contact_id: vendorId,
          contact_type: "VENDOR",
          entity_id: tenant.entityId,
          org_id: tenant.orgId || defaultOrgId,
          line_number: null,
        },
        // Line 2: Credit Paid Through (Petty Cash / Bank)
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
          contact_type: "VENDOR",
          entity_id: tenant.entityId,
          org_id: tenant.orgId || defaultOrgId,
          line_number: null,
        },
      ];

      const { error: linesErr } = await supabase
        .from("journal_entry_lines")
        .insert(lines);
      if (linesErr) {
        console.error("Error inserting journal_entry_lines:", linesErr.message);
      }
    }

    // 5. Link journal_entry_id back to payment_made_master if column exists
    try {
      await supabase
        .from("payment_made_master")
        .update({ journal_entry_id: journalEntryId })
        .eq("id", paymentId);
    } catch (_) {}
  }
}
