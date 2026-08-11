import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
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

    return this.findOne(id, tenant);
  }

  async remove(id: string, tenant: TenantContext) {
    await this.findOne(id, tenant);

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
}
