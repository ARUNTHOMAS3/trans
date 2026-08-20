import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { SupabaseService } from '../../../supabase/supabase.service';
import { TenantContext } from '../../../../common/middleware/tenant.middleware';
import { CreateVendorCreditDto } from '../dto/create-vendor-credit.dto';
import { client } from '../../../../db/db';

@Injectable()
export class VendorCreditsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(
    tenant: TenantContext,
    page: number = 1,
    limit: number = 100,
    search?: string,
    status?: string,
  ) {
    const offset = (page - 1) * limit;

    let sqlQuery = `SELECT vc.*, v.id as v_id, v.display_name, v.company_name
                    FROM vendor_credits vc
                    LEFT JOIN vendors v ON v.id = vc.vendor_id
                    WHERE vc.entity_id = $1`;
    let countQuery = `SELECT COUNT(*)::int as count FROM vendor_credits WHERE entity_id = $1`;
    const params: any[] = [tenant.entityId];

    if (status && status.trim()) {
      params.push(status.trim());
      const stIdx = params.length;
      sqlQuery += ` AND vc.status = $${stIdx}`;
      countQuery += ` AND status = $${stIdx}`;
    }

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      const sIdx = params.length;
      sqlQuery += ` AND (vc.vendor_credit_number ILIKE $${sIdx} OR vc.reference_number ILIKE $${sIdx})`;
      countQuery += ` AND (vendor_credit_number ILIKE $${sIdx} OR reference_number ILIKE $${sIdx})`;
    }

    sqlQuery += ` ORDER BY vc.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    try {
      const [rows, countRes] = await Promise.all([
        client.unsafe(sqlQuery, [...params, limit, offset]),
        client.unsafe(countQuery, params),
      ]);

      const totalCount = countRes[0]?.count ?? 0;

      const formattedData = (rows ?? []).map((row: any) => ({
        ...row,
        vendor: row.vendor_id
          ? { id: row.v_id, display_name: row.display_name, company_name: row.company_name }
          : null,
      }));

      return {
        data: formattedData,
        meta: {
          total: totalCount,
          page,
          limit,
          totalPages: Math.ceil(totalCount / limit),
        },
      };
    } catch (error: any) {
      throw new BadRequestException(error.message);
    }
  }

  async findOne(id: string, tenant: TenantContext) {
    const rows = await client.unsafe(
      `SELECT * FROM vendor_credits WHERE id = $1 AND entity_id = $2 LIMIT 1`,
      [id, tenant.entityId],
    );

    const data = rows[0];
    if (!data) {
      throw new NotFoundException(`Vendor credit with ID "${id}" not found.`);
    }

    if (data.vendor_id) {
      const v = await client.unsafe(
        `SELECT id, display_name, company_name FROM vendors WHERE id = $1 LIMIT 1`,
        [data.vendor_id],
      );
      data.vendor = v[0] ?? null;
    } else {
      data.vendor = null;
    }

    const items = await client.unsafe(
      `SELECT * FROM vendor_credit_items WHERE vendor_credit_id = $1`,
      [id],
    );

    for (const item of items ?? []) {
      const batches = await client.unsafe(
        `SELECT * FROM vendor_credit_item_batches WHERE vendor_credit_item_id = $1`,
        [item.id],
      );
      item.batches = batches ?? [];
    }
    data.items = items ?? [];

    const attachments = await client.unsafe(
      `SELECT * FROM vendor_credits_attachments WHERE vendor_credit_id = $1`,
      [id],
    );
    data.attachments = attachments ?? [];

    return { data };
  }

  async create(tenant: TenantContext, dto: CreateVendorCreditDto) {
    const { items, ...vendorCreditData } = dto;

    const payload = {
      ...vendorCreditData,
      entity_id: tenant.entityId,
      created_by: tenant.userId,
    };

    const keys = Object.keys(payload);
    const cols = keys.map((k) => `"${k}"`).join(", ");
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(", ");
    const values: any[] = Object.values(payload);

    let created: any;
    try {
      const rows = await client.unsafe(
        `INSERT INTO vendor_credits (${cols}) VALUES (${placeholders}) RETURNING *`,
        values,
      );
      created = rows[0];
    } catch (error: any) {
      throw new BadRequestException(error?.message || 'Failed to create vendor credit.');
    }

    if (!created) {
      throw new BadRequestException('Failed to create vendor credit.');
    }

    if (items && items.length > 0) {
      for (const itemDto of items) {
        const { batches, ...itemData } = itemDto;
        const itemPayload = {
          ...itemData,
          vendor_credit_id: created.id,
        };

        const itemKeys = Object.keys(itemPayload);
        const itemCols = itemKeys.map((k) => `"${k}"`).join(", ");
        const itemPlaceholders = itemKeys.map((_, i) => `$${i + 1}`).join(", ");
        const itemValues: any[] = Object.values(itemPayload);

        try {
          const itemRows = await client.unsafe(
            `INSERT INTO vendor_credit_items (${itemCols}) VALUES (${itemPlaceholders}) RETURNING *`,
            itemValues,
          );

          const createdItem = itemRows[0];
          if (batches && batches.length > 0 && createdItem) {
            for (const b of batches) {
              const bPayload = {
                ...b,
                vendor_credit_item_id: createdItem.id,
              };
              const bKeys = Object.keys(bPayload);
              const bCols = bKeys.map((k) => `"${k}"`).join(", ");
              const bPlaceholders = bKeys.map((_, i) => `$${i + 1}`).join(", ");
              const bValues: any[] = Object.values(bPayload);

              await client.unsafe(
                `INSERT INTO vendor_credit_item_batches (${bCols}) VALUES (${bPlaceholders})`,
                bValues,
              );
            }
          }
        } catch {
          // ignore single item error
        }
      }
    }

    await this.createJournalEntriesForVendorCredit(created.id, dto, tenant);

    return this.findOne(created.id, tenant);
  }

  async update(id: string, tenant: TenantContext, dto: Partial<CreateVendorCreditDto>) {
    await this.findOne(id, tenant);

    const { items, ...vendorCreditData } = dto;
    const payload: Record<string, any> = {
      ...vendorCreditData,
      updated_at: new Date().toISOString(),
    };

    const keys = Object.keys(payload);
    const setClauses = keys.map((k, i) => `"${k}" = $${i + 1}`).join(", ");
    const values: any[] = Object.values(payload);

    try {
      await client.unsafe(
        `UPDATE vendor_credits SET ${setClauses} WHERE id = $${keys.length + 1} AND entity_id = $${keys.length + 2}`,
        [...values, id, tenant.entityId],
      );
    } catch (error: any) {
      throw new BadRequestException(error.message);
    }

    await this.createJournalEntriesForVendorCredit(id, dto, tenant);

    return this.findOne(id, tenant);
  }

  async remove(id: string, tenant: TenantContext) {
    await this.findOne(id, tenant);

    const existingJE = await client.unsafe(
      `SELECT id FROM journal_entries WHERE entity_id = $1 AND source_document_type = 'vendor_credits' AND source_document_id = $2 LIMIT 1`,
      [tenant.entityId, id],
    );

    if (existingJE[0]?.id) {
      await client.unsafe(`DELETE FROM journal_entry_lines WHERE journal_entry_id = $1`, [existingJE[0].id]);
      await client.unsafe(`DELETE FROM journal_entries WHERE id = $1`, [existingJE[0].id]);
    }

    try {
      await client.unsafe(`DELETE FROM vendor_credits WHERE id = $1 AND entity_id = $2`, [id, tenant.entityId]);
    } catch (error: any) {
      throw new BadRequestException(error.message);
    }

    return { data: { success: true, id } };
  }

  private async createJournalEntriesForVendorCredit(
    vendorCreditId: string,
    dto: any,
    tenant: TenantContext,
  ) {
    const entityId = tenant.entityId;

    const dbAccounts = await client.unsafe(
      `SELECT id, user_account_name, system_account_name, account_type FROM accounts WHERE entity_id = $1`,
      [entityId],
    );

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

    const existingJE = await client.unsafe(
      `SELECT id FROM journal_entries WHERE entity_id = $1 AND source_document_type = 'vendor_credits' AND source_document_id = $2 LIMIT 1`,
      [entityId, vendorCreditId],
    );

    const journalEntryId = existingJE[0]?.id || uuidv4();
    const defaultOrgId = '00000000-0000-0000-0000-000000000000';

    if (existingJE[0]?.id) {
      await client.unsafe(`DELETE FROM journal_entry_lines WHERE journal_entry_id = $1`, [existingJE[0].id]);
      await client.unsafe(
        `UPDATE journal_entries SET
           org_id = $1, entity_id = $2, journal_number = $3, journal_type = 'vendor credit',
           journal_date = $4, posting_date = $4, reference_number = $5, narration = $6,
           source_module = 'purchase', source_document_type = 'vendor_credits', source_document_id = $7,
           currency_code = 'INR', exchange_rate = 1.0, status = 'POSTED', updated_at = NOW()
         WHERE id = $8`,
        [
          defaultOrgId,
          entityId,
          creditNoteNumber,
          vcDate,
          creditNoteNumber,
          dto.notes || `Vendor Credit ${creditNoteNumber}`,
          vendorCreditId,
          journalEntryId,
        ],
      );
    } else {
      await client.unsafe(
        `INSERT INTO journal_entries (id, org_id, entity_id, journal_number, journal_type, journal_date, posting_date, reference_number, narration, source_module, source_document_type, source_document_id, currency_code, exchange_rate, status)
         VALUES ($1, $2, $3, $4, 'vendor credit', $5, $5, $6, $7, 'purchase', 'vendor_credits', $8, 'INR', 1.0, 'POSTED')`,
        [
          journalEntryId,
          defaultOrgId,
          entityId,
          creditNoteNumber,
          vcDate,
          creditNoteNumber,
          dto.notes || `Vendor Credit ${creditNoteNumber}`,
          vendorCreditId,
        ],
      );
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
      });
    }

    if (entries.length > 0) {
      for (const entry of entries) {
        await client.unsafe(
          `INSERT INTO journal_entry_lines (id, journal_entry_id, entity_id, org_id, account_id, transaction_date, reference_number, description, debit, credit, source_id, source_type, contact_id, contact_type)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`,
          [
            entry.id,
            entry.journal_entry_id,
            entry.entity_id,
            entry.org_id,
            entry.account_id,
            entry.transaction_date,
            entry.reference_number,
            entry.description,
            entry.debit,
            entry.credit,
            entry.source_id,
            entry.source_type,
            entry.contact_id,
            entry.contact_type,
          ],
        );
      }
    }

    try {
      await client.unsafe(
        `UPDATE vendor_credits SET journal_id = $1 WHERE id = $2`,
        [journalEntryId, vendorCreditId],
      );
    } catch (_) {}
  }
}
