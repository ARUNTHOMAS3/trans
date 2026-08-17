import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { SupabaseService } from '../../../supabase/supabase.service';
import { TenantContext } from '../../../../common/middleware/tenant.middleware';
import { CreateVendorCreditDto } from '../dto/create-vendor-credit.dto';

@Injectable()
export class VendorCreditsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  private get client() {
    return this.supabaseService.getClient();
  }

  async findAll(
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    search?: string,
    status?: string,
  ) {
    const offset = (page - 1) * limit;
    let query = this.client
      .from('vendor_credits')
      .select('*, vendor:vendors(id, display_name, company_name)', { count: 'exact' })
      .eq('entity_id', tenant.entityId)
      .order('created_at', { ascending: false });

    if (status && status.trim()) {
      query = query.eq('status', status.trim());
    }

    if (search && search.trim()) {
      query = query.or(`vendor_credit_number.ilike.%${search.trim()}%,reference_number.ilike.%${search.trim()}%`);
    }

    const { data, count, error } = await query.range(offset, offset + limit - 1);

    if (error) {
      throw new BadRequestException(error.message);
    }

    return {
      data: data || [],
      meta: {
        total: count || 0,
        page,
        limit,
        totalPages: Math.ceil((count || 0) / limit),
      },
    };
  }

  async findOne(id: string, tenant: TenantContext) {
    const { data, error } = await this.client
      .from('vendor_credits')
      .select(`
        *,
        vendor:vendors(id, display_name, company_name),
        items:vendor_credit_items(
          *,
          batches:vendor_credit_item_batches(*)
        ),
        attachments:vendor_credits_attachments(*)
      `)
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .single();

    if (error || !data) {
      throw new NotFoundException(`Vendor credit with ID "${id}" not found.`);
    }

    return { data };
  }

  async create(tenant: TenantContext, dto: CreateVendorCreditDto) {
    const { items, ...vendorCreditData } = dto;

    const payload = {
      ...vendorCreditData,
      entity_id: tenant.entityId,
      created_by: tenant.userId,
    };

    const { data: created, error } = await this.client
      .from('vendor_credits')
      .insert(payload)
      .select()
      .single();

    if (error || !created) {
      throw new BadRequestException(error?.message || 'Failed to create vendor credit.');
    }

    if (items && items.length > 0) {
      for (const itemDto of items) {
        const { batches, ...itemData } = itemDto;
        const itemPayload = {
          ...itemData,
          vendor_credit_id: created.id,
        };

        const { data: createdItem, error: itemError } = await this.client
          .from('vendor_credit_items')
          .insert(itemPayload)
          .select()
          .single();

        if (itemError) continue;

        if (batches && batches.length > 0 && createdItem) {
          const batchPayloads = batches.map((b) => ({
            ...b,
            vendor_credit_item_id: createdItem.id,
          }));
          await this.client.from('vendor_credit_item_batches').insert(batchPayloads);
        }
      }
    }

    await this.createJournalEntriesForVendorCredit(created.id, dto, tenant);

    return this.findOne(created.id, tenant);
  }

  async update(id: string, tenant: TenantContext, dto: Partial<CreateVendorCreditDto>) {
    await this.findOne(id, tenant);

    const { items, ...vendorCreditData } = dto;
    const payload = {
      ...vendorCreditData,
      updated_at: new Date().toISOString(),
    };

    const { error } = await this.client
      .from('vendor_credits')
      .update(payload)
      .eq('id', id)
      .eq('entity_id', tenant.entityId);

    if (error) {
      throw new BadRequestException(error.message);
    }

    await this.createJournalEntriesForVendorCredit(id, dto, tenant);

    return this.findOne(id, tenant);
  }

  async remove(id: string, tenant: TenantContext) {
    await this.findOne(id, tenant);

    // Delete corresponding journal_entry_lines and journal_entries
    const { data: existingJE } = await this.client
      .from('journal_entries')
      .select('id')
      .eq('entity_id', tenant.entityId)
      .eq('source_document_type', 'vendor_credits')
      .eq('source_document_id', id)
      .maybeSingle();

    if (existingJE?.id) {
      await this.client.from('journal_entry_lines').delete().eq('journal_entry_id', existingJE.id);
      await this.client.from('journal_entries').delete().eq('id', existingJE.id);
    }

    const { error } = await this.client
      .from('vendor_credits')
      .delete()
      .eq('id', id)
      .eq('entity_id', tenant.entityId);

    if (error) {
      throw new BadRequestException(error.message);
    }

    return { data: { success: true, id } };
  }

  private async createJournalEntriesForVendorCredit(
    vendorCreditId: string,
    dto: any,
    tenant: TenantContext,
  ) {
    const supabase = this.client;
    const entityId = tenant.entityId;

    const { data: dbAccounts } = await supabase
      .from('accounts')
      .select('id, user_account_name, system_account_name, account_type')
      .eq('entity_id', entityId);

    if (!dbAccounts || dbAccounts.length === 0) return;

    const findAccount = (names: string[], types?: string[]): string | null => {
      const match = dbAccounts.find((acc: any) => {
        const uName = acc.user_account_name?.toLowerCase() || '';
        const sName = acc.system_account_name?.toLowerCase() || '';
        const aType = acc.account_type?.toLowerCase() || '';

        const nameMatch = names.some(n => {
          const ln = n.toLowerCase();
          return uName.includes(ln) || sName.includes(ln);
        });

        const typeMatch = types ? types.some(t => aType === t.toLowerCase()) : true;
        return nameMatch && typeMatch;
      });

      if (match) return match.id;
      if (types && types.length > 0) {
        const typeMatch = dbAccounts.find((acc: any) =>
          types.some(t => acc.account_type?.toLowerCase() === t.toLowerCase())
        );
        if (typeMatch) return typeMatch.id;
      }
      return dbAccounts[0]?.id || null;
    };

    const apAccountId = findAccount(['Accounts Payable'], ['Accounts Payable']);

    const creditNoteNumber = dto.vendor_credit_number || dto.credit_note_number || dto.reference_number || 'VC-00001';
    const vcDate = dto.vendor_credit_date || new Date().toISOString().split('T')[0];

    const { data: existingJE } = await supabase
      .from('journal_entries')
      .select('id')
      .eq('entity_id', entityId)
      .eq('source_document_type', 'vendor_credits')
      .eq('source_document_id', vendorCreditId)
      .maybeSingle();

    const journalEntryId = existingJE?.id || uuidv4();

    if (existingJE?.id) {
      await supabase
        .from('journal_entry_lines')
        .delete()
        .eq('journal_entry_id', existingJE.id);
    }

    const defaultOrgId = '00000000-0000-0000-0000-000000000000';
    const jeHeader = {
      id: journalEntryId,
      org_id: defaultOrgId,
      entity_id: entityId,
      journal_number: creditNoteNumber,
      journal_type: 'vendor credit',
      journal_date: vcDate,
      posting_date: vcDate,
      reference_number: creditNoteNumber,
      narration: dto.notes || `Vendor Credit ${creditNoteNumber}`,
      source_module: 'purchase',
      source_document_type: 'vendor_credits',
      source_document_id: vendorCreditId,
      currency_code: 'INR',
      exchange_rate: 1.0,
      status: 'POSTED',
      updated_at: new Date().toISOString(),
    };

    if (existingJE?.id) {
      await supabase
        .from('journal_entries')
        .update(jeHeader)
        .eq('id', journalEntryId);
    } else {
      await supabase
        .from('journal_entries')
        .insert({
          ...jeHeader,
          created_at: new Date().toISOString(),
        });
    }

    const entries: any[] = [];
    let totalCreditSum = 0;

    for (const item of dto.items || []) {
      const itemAccId = item.account_id || item.accountId;
      const qty = parseFloat(item.quantity?.toString() || '0');
      const rate = parseFloat(item.rate?.toString() || '0');
      const itemTotal = parseFloat(item.line_total?.toString() || (qty * rate).toString() || '0');

      if (itemAccId && itemTotal > 0.0001) {
        totalCreditSum += itemTotal;
        entries.push({
          id: uuidv4(),
          journal_entry_id: journalEntryId,
          entity_id: entityId,
          org_id: defaultOrgId,
          account_id: itemAccId,
          transaction_date: vcDate,
          reference_number: creditNoteNumber,
          description: item.remarks || dto.notes || 'Vendor Credit transaction',
          debit: 0,
          credit: Math.round(itemTotal * 100) / 100,
          source_id: vendorCreditId,
          source_type: 'VENDOR_CREDIT',
          contact_id: dto.vendor_id || dto.vendorId || null,
          contact_type: (dto.vendor_id || dto.vendorId) ? 'vendor' : null,
          line_number: null,
        });
      }
    }

    const grandTotal = parseFloat(dto.total_amount?.toString() || dto.total?.toString() || '0');
    if (entries.length === 0 && grandTotal > 0.0001) {
      const fallbackAccId = dbAccounts[0]?.id;
      totalCreditSum = grandTotal;
      entries.push({
        id: uuidv4(),
        journal_entry_id: journalEntryId,
        entity_id: entityId,
        org_id: defaultOrgId,
        account_id: fallbackAccId,
        transaction_date: vcDate,
        reference_number: creditNoteNumber,
        description: dto.notes || 'Vendor Credit transaction',
        debit: 0,
        credit: Math.round(grandTotal * 100) / 100,
        source_id: vendorCreditId,
        source_type: 'VENDOR_CREDIT',
        contact_id: dto.vendor_id || dto.vendorId || null,
        contact_type: (dto.vendor_id || dto.vendorId) ? 'vendor' : null,
        line_number: null,
      });
    }

    if (apAccountId && totalCreditSum > 0.0001) {
      entries.unshift({
        id: uuidv4(),
        journal_entry_id: journalEntryId,
        entity_id: entityId,
        org_id: defaultOrgId,
        account_id: apAccountId,
        transaction_date: vcDate,
        reference_number: creditNoteNumber,
        description: dto.notes || 'Accounts Payable debit for Vendor Credit',
        debit: Math.round(totalCreditSum * 100) / 100,
        credit: 0,
        source_id: vendorCreditId,
        source_type: 'VENDOR_CREDIT',
        contact_id: dto.vendor_id || dto.vendorId || null,
        contact_type: (dto.vendor_id || dto.vendorId) ? 'vendor' : null,
        line_number: null,
      });
    }

    if (entries.length > 0) {
      await supabase.from('journal_entry_lines').insert(entries);
    }

    try {
      await supabase
        .from('vendor_credits')
        .update({ journal_id: journalEntryId })
        .eq('id', vendorCreditId);
    } catch (_) {}
  }
}
