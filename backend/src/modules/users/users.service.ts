import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

// TODO(auth): Once auth is enabled, filter users by org_id from user_metadata
// or app_metadata (set at sign-up). For now auth is disabled so we return all
// users from auth.users unfiltered — the org_id query param is accepted but
// ignored. Re-enable the org filter in findAll() and findOne() when auth lands.

@Injectable()
export class UsersService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(_orgId: string): Promise<any[]> {
    const client = this.supabaseService.getClient();
    const { data, error } = await client.auth.admin.listUsers({ perPage: 1000 });

    if (error) {
      throw new Error(`Failed to list users: ${error.message}`);
    }

    return (data?.users ?? []).map((u) => ({
      id: u.id,
      email: u.email ?? '',
      name: (u.user_metadata?.full_name ?? u.user_metadata?.name ?? u.email ?? '').toString(),
      full_name: (u.user_metadata?.full_name ?? u.user_metadata?.name ?? '').toString(),
      role: (u.user_metadata?.role ?? u.app_metadata?.role ?? 'user').toString(),
      is_active: !u.banned_until,
      created_at: u.created_at,
    }));
  }

  async findOne(id: string, _orgId: string): Promise<any | null> {
    const client = this.supabaseService.getClient();
    const { data, error } = await client.auth.admin.getUserById(id);

    if (error || !data?.user) return null;

    const u = data.user;
    const meta = u.user_metadata ?? {};

    return {
      id: u.id,
      email: u.email ?? '',
      name: (meta.full_name ?? meta.name ?? u.email ?? '').toString(),
      full_name: (meta.full_name ?? meta.name ?? '').toString(),
      role: (meta.role ?? u.app_metadata?.role ?? 'user').toString(),
      is_active: !u.banned_until,
      created_at: u.created_at,
    };
  }
}
