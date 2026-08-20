import {
  ForbiddenException,
  Injectable,
  Logger,
  ServiceUnavailableException,
  UnauthorizedException,
} from "@nestjs/common";
import { createClient, SupabaseClient } from "@supabase/supabase-js";
import { SupabaseService } from "../../modules/supabase/supabase.service";
import { ResendService } from "../../modules/email/resend.service";
import { client as pgClient } from "../../db/db";

export interface JwtPayload {
  sub: string;
  email: string;
  orgId: string;
  branchId: string | null;
  role: string;
  accessibleBranchIds: string[];
  defaultBusinessBranchId: string | null;
  defaultWarehouseBranchId: string | null;
  permissions: Record<string, unknown> | null;
  user: Record<string, unknown>;
}

@Injectable()
export class AuthService {
  private anonClient: SupabaseClient | null = null;
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly resendService: ResendService,
  ) {}

  private normalizeRole(role: unknown): string {
    const rawValue = role?.toString().trim() ?? "";
    const value = rawValue.toLowerCase();
    const isUuid =
      /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$/.test(
        rawValue,
      );

    if (isUuid) {
      return rawValue;
    }

    switch (value) {
      case "super_admin":
        return "admin";
      case "ho admin":
        return "ho_admin";
      case "branch admin":
        return "branch_admin";
      case "manager":
      case "staff":
      case "branch_manager":
      case "branch_staff":
        return "branch_admin";
      case "admin":
      case "ho_admin":
      case "branch_admin":
        return value;
      default:
        return rawValue;
    }
  }

  private getAnonClient(): SupabaseClient {
    if (this.anonClient != null) return this.anonClient;

    const supabaseUrl = process.env.SUPABASE_URL;
    const anonKey = process.env.SUPABASE_ANON_KEY;

    if (!supabaseUrl || !anonKey) {
      throw new Error("Missing SUPABASE_URL or SUPABASE_ANON_KEY");
    }

    this.anonClient = createClient(supabaseUrl, anonKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    return this.anonClient;
  }

  private getBuiltinRoleLabel(role: string): string {
    switch (role) {
      case "ho_admin":
        return "HO Admin";
      case "branch_admin":
        return "Branch Admin";
      default:
        return role;
    }
  }

  private mergePermissionActions(
    existing: unknown,
    requiredActions: string[],
  ): string[] {
    const values = Array.isArray(existing)
      ? existing.map((entry) => String(entry))
      : [];
    const merged = new Set<string>(values);
    for (const action of requiredActions) {
      merged.add(action);
    }
    return Array.from(merged);
  }

  private isTransientSupabaseReadError(error: unknown): boolean {
    const message = `${(error as any)?.code ?? ""} ${(error as any)?.message ?? ""}`
      .toLowerCase()
      .trim();
    if (!message) return false;

    return (
      message.includes("schema cache") ||
      message.includes("timed out acquiring connection from connection pool") ||
      message.includes("statement timeout") ||
      message.includes("canceling statement due to statement timeout") ||
      message.includes("pgrst003")
    );
  }

  private throwSupabaseReadError(context: string, error: any): never {
    if (this.isTransientSupabaseReadError(error)) {
      throw new ServiceUnavailableException(
        `${context} temporarily unavailable. Please retry.`,
      );
    }
    throw new Error(`Failed to fetch ${context}: ${error.message}`);
  }

  private async findPublicUser(userId: string) {
    try {
      const rows = await pgClient.unsafe<any[]>(
        `SELECT id, email, full_name, role, entity_id, org_id, is_active FROM users WHERE id = $1 LIMIT 1`,
        [userId],
      );
      return rows.length > 0 ? rows[0] : null;
    } catch (err: any) {
      this.logger.error(
        `Failed to fetch public users row for ${userId}: ${err.message}`,
      );
      return null;
    }
  }

  private async findOrganization(orgId: string) {
    try {
      const rows = await pgClient.unsafe<any[]>(
        `SELECT id, name, system_id FROM organization WHERE id = $1 LIMIT 1`,
        [orgId],
      );
      return rows.length > 0 ? rows[0] : null;
    } catch (err: any) {
      this.throwSupabaseReadError("organization", err);
      return null;
    }
  }

  private async findBranchSystemId(branchId?: string | null) {
    const normalized = branchId?.toString().trim();
    if (!normalized) return null;
    const isUuid =
      /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$/.test(
        normalized,
      );
    if (!isUuid) return null;

    const { data, error } = await this.supabaseService
      .getClient()
      .from("branches")
      .select("id, system_id")
      .eq("id", normalized)
      .maybeSingle();

    if (error) {
      return null;
    }

    return data?.["system_id"]?.toString() ?? null;
  }

  private async findBranchEntityIdByRefId(branchId?: string | null) {
    const normalized = branchId?.toString().trim();
    if (!normalized) return null;
    const isUuid =
      /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$/.test(
        normalized,
      );
    if (!isUuid) return null;

    const { data, error } = await this.supabaseService
      .getClient()
      .from("organisation_branch_master")
      .select("id")
      .eq("ref_id", normalized)
      .eq("type", "BRANCH")
      .maybeSingle();

    if (error) {
      return null;
    }

    return data?.["id"]?.toString() ?? null;
  }

  private async findBranchRefIdByEntityId(entityId?: string | null) {
    const normalized = entityId?.toString().trim();
    if (!normalized) return null;
    const isUuid =
      /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$/.test(
        normalized,
      );
    if (!isUuid) return null;

    const { data, error } = await this.supabaseService
      .getClient()
      .from("organisation_branch_master")
      .select("ref_id, type")
      .eq("id", normalized)
      .eq("type", "BRANCH")
      .maybeSingle();

    if (error) return null;
    return data?.["ref_id"]?.toString() ?? null;
  }

  private async findAccessibleBranchIdsFromAccess(
    userId: string,
    orgId: string,
  ): Promise<string[]> {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("user_branch_access")
      .select("entity_id")
      .eq("user_id", userId)
      .eq("org_id", orgId);

    if (error || !Array.isArray(data) || data.length === 0) {
      return [];
    }

    const entityIds = data
      .map((row: any) => row?.entity_id?.toString().trim() ?? "")
      .filter((value: string) => value.length > 0);
    if (entityIds.length === 0) {
      return [];
    }

    const { data: branches, error: branchError } = await this.supabaseService
      .getClient()
      .from("organisation_branch_master")
      .select("id, ref_id, type")
      .in("id", entityIds)
      .eq("type", "BRANCH");

    if (branchError || !Array.isArray(branches)) {
      return [];
    }

    const ids = new Set<string>();
    for (const row of branches) {
      const branchId = row?.["ref_id"]?.toString().trim() ?? "";
      if (branchId) ids.add(branchId);
    }
    return Array.from(ids);
  }

  private async findBranchAccessSummary(userId: string, orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("user_branch_access")
      .select("entity_id, is_default_business, is_default_warehouse")
      .eq("user_id", userId)
      .eq("org_id", orgId);

    if (error) {
      this.throwSupabaseReadError("user branch access", error);
    }

    if (!Array.isArray(data) || data.length === 0) {
      return {
        accessibleBranchIds: [] as string[],
        defaultBusinessBranchId: null as string | null,
        defaultWarehouseBranchId: null as string | null,
      };
    }

    const entityIds = data
      .map((row: any) => row?.entity_id?.toString().trim() ?? "")
      .filter((value: string) => value.length > 0);
    if (entityIds.length === 0) {
      return {
        accessibleBranchIds: [] as string[],
        defaultBusinessBranchId: null as string | null,
        defaultWarehouseBranchId: null as string | null,
      };
    }

    const { data: branchRows, error: branchError } = await this.supabaseService
      .getClient()
      .from("organisation_branch_master")
      .select("id, ref_id, type")
      .in("id", entityIds)
      .eq("type", "BRANCH");

    if (branchError) {
      this.throwSupabaseReadError("branch access entities", branchError);
    }

    const branchByEntityId = new Map<string, string>();
    for (const row of branchRows ?? []) {
      const entityId = row?.["id"]?.toString().trim() ?? "";
      const branchId = row?.["ref_id"]?.toString().trim() ?? "";
      if (entityId && branchId) {
        branchByEntityId.set(entityId, branchId);
      }
    }

    const accessibleBranchIds: string[] = [];
    let defaultBusinessBranchId: string | null = null;
    let defaultWarehouseBranchId: string | null = null;

    for (const row of data) {
      const entityId = row?.["entity_id"]?.toString().trim() ?? "";
      const branchId = branchByEntityId.get(entityId);
      if (!branchId) continue;

      accessibleBranchIds.push(branchId);
      if (row?.["is_default_business"] === true && !defaultBusinessBranchId) {
        defaultBusinessBranchId = branchId;
      }
      if (row?.["is_default_warehouse"] === true && !defaultWarehouseBranchId) {
        defaultWarehouseBranchId = branchId;
      }
    }

    return {
      accessibleBranchIds: Array.from(new Set(accessibleBranchIds)),
      defaultBusinessBranchId,
      defaultWarehouseBranchId,
    };
  }

  private async buildRoleContext(entityId: string, roleId: string) {
    const normalizedRole = this.normalizeRole(roleId);
    if (normalizedRole === "admin") {
      return {
        permissions: { full_access: true },
        label: this.getBuiltinRoleLabel(normalizedRole),
        isDefault: true,
      };
    }

    // Built-in roles are handled above; only custom org roles should hit settings_roles.
    const isUuid =
      /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$/.test(
        roleId,
      );

    const query = this.supabaseService
      .getClient()
      .from("roles")
      .select("permissions, label");

    const response = isUuid
      ? await query.eq("entity_id", entityId).eq("id", roleId).maybeSingle()
      : await query
          .eq("entity_id", entityId)
          .ilike("label", this.getBuiltinRoleLabel(normalizedRole))
          .maybeSingle();

    const { data, error } = response;

    if (error) {
      this.throwSupabaseReadError("settings role permissions", error);
    }

    let permissions: Record<string, unknown> = {};
    let label = this.getBuiltinRoleLabel(normalizedRole);

    if (data?.label) {
      label = data.label.toString();
    }

    if (data?.permissions != null) {
      permissions = data.permissions as Record<string, unknown>;
    }

    // If the DB role row exists but has no permissions JSON set yet, check if its
    // label maps to a built-in role and use the built-in default. This prevents
    // newly created roles (or roles migrated without a permissions column) from
    // blocking all API access during initial setup.
    if (data?.label) {
      const labelNormalized = this.normalizeRole(data.label as string);
      if (labelNormalized === "ho_admin") {
        permissions = { full_access: true };
      }
      if (labelNormalized === "branch_admin") {
        const nextPermissions = {
          ...permissions,
          branches: ["view", "edit"],
          users: this.mergePermissionActions(permissions["users"], ["view"]),
          transaction_series: this.mergePermissionActions(
            permissions["transaction_series"],
            ["view", "create", "edit", "delete"],
          ),
        } as Record<string, unknown>;
        delete nextPermissions["users_roles"];
        permissions = nextPermissions;
      }
    }

    return {
      permissions,
      label,
      isDefault: normalizedRole === "admin",
    };
  }

  private async findOrgEntityId(orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("organisation_branch_master")
      .select("id")
      .eq("type", "ORG")
      .eq("ref_id", orgId)
      .maybeSingle();

    if (error) return null;
    return data?.id?.toString() ?? null;
  }

  private async findOrgIdByUserEntityId(entityId?: string | null) {
    const normalized = entityId?.toString().trim();
    if (!normalized) return null;
    const isUuid =
      /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$/.test(
        normalized,
      );
    if (!isUuid) return null;

    const { data: entityRow, error: entityError } = await this.supabaseService
      .getClient()
      .from("organisation_branch_master")
      .select("id, type, ref_id, parent_id")
      .eq("id", normalized)
      .maybeSingle();

    if (entityError || !entityRow) return null;

    const type = entityRow["type"]?.toString();
    if (type === "ORG") {
      return entityRow["ref_id"]?.toString() ?? null;
    }

    if (type === "BRANCH") {
      const parentId = entityRow["parent_id"]?.toString() ?? null;
      if (!parentId) return null;
      const { data: parentRow, error: parentError } = await this.supabaseService
        .getClient()
        .from("organisation_branch_master")
        .select("type, ref_id")
        .eq("id", parentId)
        .eq("type", "ORG")
        .maybeSingle();

      if (parentError || !parentRow) return null;
      return parentRow["ref_id"]?.toString() ?? null;
    }

    return null;
  }

  private async resolveOrgIdFromAuthOrUser(
    authUser: any,
    publicUser: any,
  ): Promise<string | null> {
    const metadataOrgId =
      authUser?.app_metadata?.["org_id"]?.toString() ??
      authUser?.user_metadata?.["org_id"]?.toString() ??
      null;
    if (metadataOrgId && metadataOrgId.trim().length > 0) {
      return metadataOrgId.trim();
    }

    return this.findOrgIdByUserEntityId(publicUser?.["entity_id"]?.toString());
  }

  private async buildAuthenticatedUser(
    userId: string,
    orgId: string,
    publicUserOverride?: any,
    authUser?: any,
  ) {
    let userRecord = publicUserOverride;
    if (!userRecord) {
      userRecord = await this.findPublicUser(userId);
    }

    if (!userRecord && authUser) {
      userRecord = {
        id: authUser.id,
        email: authUser.email,
        full_name:
          authUser.user_metadata?.full_name ??
          authUser.user_metadata?.name ??
          authUser.email ??
          "",
        name:
          authUser.user_metadata?.name ??
          authUser.user_metadata?.full_name ??
          authUser.email ??
          "",
        role:
          authUser.user_metadata?.role ??
          authUser.app_metadata?.role ??
          "admin",
        entity_id:
          authUser.user_metadata?.entity_id ??
          authUser.app_metadata?.entity_id ??
          null,
        is_active: true,
      };
    }

    if (!userRecord) {
      const { data: authAdminData } = await this.supabaseService
        .getClient()
        .auth.admin.getUserById(userId);
      if (authAdminData?.user) {
        const u = authAdminData.user;
        userRecord = {
          id: u.id,
          email: u.email,
          full_name:
            u.user_metadata?.full_name ??
            u.user_metadata?.name ??
            u.email ??
            "",
          name:
            u.user_metadata?.name ??
            u.user_metadata?.full_name ??
            u.email ??
            "",
          role:
            u.user_metadata?.role ??
            u.app_metadata?.role ??
            "admin",
          entity_id:
            u.user_metadata?.entity_id ??
            u.app_metadata?.entity_id ??
            null,
          is_active: !(u.banned_until != null),
        };
      }
    }

    if (!userRecord) {
      throw new UnauthorizedException("User profile not found");
    }

    const [organization, orgEntityId, branchAccess] = await Promise.all([
      this.findOrganization(orgId),
      this.findOrgEntityId(orgId),
      this.findBranchAccessSummary(userId, orgId),
    ]);

    const normalizedRole = this.normalizeRole(userRecord["role"]);
    const roleContext = await this.buildRoleContext(
      orgEntityId ?? orgId,
      normalizedRole,
    );
    let accessibleBranchIds = branchAccess.accessibleBranchIds;
    let defaultBusinessBranchId = branchAccess.defaultBusinessBranchId;
    let defaultWarehouseBranchId =
      branchAccess.defaultWarehouseBranchId ??
      userRecord["default_warehouse_branch_id"]?.toString() ??
      null;

    // Fallback for branch-scoped users missing explicit access/default rows:
    // derive branch ref_id from users.entity_id (organisation_branch_master).
    if (accessibleBranchIds.length === 0 || !defaultBusinessBranchId) {
      const derivedBranchId = await this.findBranchRefIdByEntityId(
        userRecord["entity_id"]?.toString(),
      );
      if (derivedBranchId) {
        if (accessibleBranchIds.length === 0) {
          accessibleBranchIds = [derivedBranchId];
        }
        if (!defaultBusinessBranchId) {
          defaultBusinessBranchId = derivedBranchId;
        }
      }
    }
    if (!defaultBusinessBranchId && accessibleBranchIds.length > 0) {
      defaultBusinessBranchId = accessibleBranchIds[0];
    }

    if (accessibleBranchIds.length === 0) {
      const fromAccess = await this.findAccessibleBranchIdsFromAccess(
        userId,
        orgId,
      );
      if (fromAccess.length > 0) {
        accessibleBranchIds = fromAccess;
        if (!defaultBusinessBranchId) {
          defaultBusinessBranchId = fromAccess[0];
        }
      }
    }

    const primaryBranchId =
      defaultBusinessBranchId ?? accessibleBranchIds[0] ?? null;
    const [branchSystemId, defaultBusinessBranchEntityId] = await Promise.all([
      this.findBranchSystemId(primaryBranchId),
      this.findBranchEntityIdByRefId(primaryBranchId),
    ]);
    const orgSystemId = organization?.["system_id"]?.toString() ?? "";
    const routeSystemId = branchSystemId ?? orgSystemId;

    return {
      id: userRecord["id"]?.toString() ?? userId,
      email: userRecord["email"]?.toString() ?? "",
      fullName:
        userRecord["full_name"]?.toString() ??
        userRecord["name"]?.toString() ??
        "",
      role: normalizedRole,
      orgId,
      orgEntityId,
      orgName: organization?.["name"]?.toString() ?? "",
      orgSystemId,
      routeSystemId,
      isActive: userRecord["is_active"] == true,
      createdAt: userRecord["created_at"]?.toString(),
      updatedAt: userRecord["updated_at"]?.toString(),
      roleLabel: roleContext.label,
      roleIsDefault: roleContext.isDefault,
      accessibleBranchIds,
      defaultBusinessBranchId,
      defaultBusinessBranchEntityId,
      defaultWarehouseBranchId,
      permissions: roleContext.permissions,
    };
  }

  async login(email: string, password: string) {
    const { data, error } = await this.getAnonClient().auth.signInWithPassword({
      email,
      password,
    });

    if (error || !data.session || !data.user) {
      throw new UnauthorizedException(error?.message ?? "Invalid credentials");
    }

    const publicUser = await this.findPublicUser(data.user.id);
    const orgId = await this.resolveOrgIdFromAuthOrUser(data.user, publicUser);

    if (!orgId) {
      throw new UnauthorizedException("User is not mapped to an organization");
    }

    const user = await this.buildAuthenticatedUser(
      data.user.id,
      orgId,
      publicUser,
      data.user,
    );

    return {
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_at: data.session.expires_at,
      user,
    };
  }

  async refreshToken(refreshToken: string) {
    const { data, error } = await this.getAnonClient().auth.refreshSession({
      refresh_token: refreshToken,
    });

    if (error || !data.session || !data.user) {
      throw new UnauthorizedException(
        error?.message ?? "Invalid refresh token",
      );
    }

    const publicUser = await this.findPublicUser(data.user.id);
    const orgId = await this.resolveOrgIdFromAuthOrUser(data.user, publicUser);

    if (!orgId) {
      throw new UnauthorizedException("User is not mapped to an organization");
    }

    const user = await this.buildAuthenticatedUser(
      data.user.id,
      orgId,
      publicUser,
      data.user,
    );

    return {
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_at: data.session.expires_at,
      user,
    };
  }

  async logout(accessToken?: string, refreshToken?: string) {
    if (accessToken && refreshToken) {
      const client = this.getAnonClient();
      await client.auth.setSession({
        access_token: accessToken,
        refresh_token: refreshToken,
      });
      await client.auth.signOut();
    }

    return { success: true };
  }

  async requestPasswordReset(email: string, redirectTo?: string) {
    const normalizedRedirect =
      redirectTo?.trim() || process.env.AUTH_RESET_REDIRECT_URL?.trim();
    const provider =
      process.env.AUTH_PASSWORD_RESET_PROVIDER?.trim().toLowerCase() ||
      "supabase";

    if (provider === "resend") {
      const { data, error } = await this.supabaseService
        .getClient()
        .auth.admin.generateLink({
          type: "recovery",
          email,
          options: normalizedRedirect ? { redirectTo: normalizedRedirect } : {},
        });

      if (error) {
        throw error;
      }

      const actionLink =
        data.properties?.action_link ??
        data.properties?.email_otp ??
        normalizedRedirect;

      if (!actionLink) {
        throw new Error("Failed to generate a password reset link");
      }

      await this.resendService.sendEmail({
        to: email,
        subject: "Reset your Zerpai ERP password",
        html: `
          <p>Hello,</p>
          <p>Use the link below to reset your Zerpai ERP password.</p>
          <p><a href="${actionLink}">Reset password</a></p>
          <p>If you did not request this, you can ignore this email.</p>
        `,
      });

      return { success: true, provider: "resend" };
    }

    const { error: resetError } = await this.getAnonClient().auth
      .resetPasswordForEmail(
        email,
        normalizedRedirect ? { redirectTo: normalizedRedirect } : undefined,
      );

    if (resetError) {
      this.logger.error(
        `Password reset email failed via supabase for ${email}: ${resetError.message}`,
      );
      throw new UnauthorizedException(resetError.message);
    }

    return { success: true, provider: "supabase" };
  }

  async changePassword(
    accessToken: string,
    refreshToken: string,
    newPassword: string,
  ) {
    const client = this.getAnonClient();
    const { error: sessionError } = await client.auth.setSession({
      access_token: accessToken,
      refresh_token: refreshToken,
    });

    if (sessionError) {
      throw new UnauthorizedException(sessionError.message);
    }

    const { error } = await client.auth.updateUser({ password: newPassword });
    if (error) {
      throw new UnauthorizedException(error.message);
    }

    return { success: true };
  }

  async validateToken(token: string): Promise<JwtPayload> {
    const { data, error } = await this.supabaseService
      .getClient()
      .auth.getUser(token);

    if (error || !data.user) {
      throw new UnauthorizedException(error?.message ?? "Invalid token");
    }

    const publicUser = await this.findPublicUser(data.user.id);
    const orgId = await this.resolveOrgIdFromAuthOrUser(data.user, publicUser);

    if (!orgId) {
      throw new UnauthorizedException("User organization not found");
    }

    const user = await this.buildAuthenticatedUser(
      data.user.id,
      orgId,
      publicUser,
      data.user,
    );
    if (user.isActive != true) {
      throw new ForbiddenException("User is inactive");
    }

    return {
      sub: user.id,
      email: user.email,
      orgId: user.orgId,
      branchId: user.defaultBusinessBranchId ?? user.accessibleBranchIds[0] ?? null,
      role: user.role,
      accessibleBranchIds: user.accessibleBranchIds,
      defaultBusinessBranchId: user.defaultBusinessBranchId ?? null,
      defaultWarehouseBranchId: user.defaultWarehouseBranchId ?? null,
      permissions: user.permissions,
      user,
    };
  }
}
