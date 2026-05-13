import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { createClient, SupabaseClient } from "@supabase/supabase-js";
import { SupabaseService } from "../../modules/supabase/supabase.service";
import { UsersService } from "../../modules/users/users.service";
import { ResendService } from "../../modules/email/resend.service";

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

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly usersService: UsersService,
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

  private async findPublicUser(userId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("users")
      .select("id, email, full_name, role, entity_id, is_active")
      .eq("id", userId)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to fetch users row: ${error.message}`);
    }

    return data ?? null;
  }

  private async findOrganization(orgId: string) {
    const { data, error } = await this.supabaseService
      .getClient()
      .from("organization")
      .select("id, name, system_id")
      .eq("id", orgId)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to fetch organization: ${error.message}`);
    }

    return data ?? null;
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

  private async buildRolePermissions(entityId: string, roleId: string) {
    const normalizedRole = this.normalizeRole(roleId);
    if (normalizedRole === "admin") {
      return { full_access: true };
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
      throw new Error(
        `Failed to fetch settings role permissions: ${error.message}`,
      );
    }

    if (data?.permissions != null) {
      return data.permissions as Record<string, unknown>;
    }

    // If the DB role row exists but has no permissions JSON set yet, check if its
    // label maps to a built-in role and use the built-in default. This prevents
    // newly created roles (or roles migrated without a permissions column) from
    // blocking all API access during initial setup.
    if (data?.label) {
      const labelNormalized = this.normalizeRole(data.label as string);
      if (labelNormalized === "ho_admin") {
        return { full_access: true };
      }
      if (labelNormalized === "branch_admin") {
        return { full_access: true };
      }
    }

    return {};
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

  private async buildAuthenticatedUser(userId: string, orgId: string) {
    const [organization, orgEntityId] = await Promise.all([
      this.findOrganization(orgId),
      this.findOrgEntityId(orgId),
    ]);

    let userRecord: any;
    if (orgEntityId) {
      userRecord = await this.usersService.findOne(userId, {
        orgId,
        entityId: orgEntityId,
      } as any);
    } else {
      // orgEntityId not yet in organisation_branch_master — fall back to direct users table lookup
      userRecord = await this.findPublicUser(userId);
    }

    if (!userRecord) {
      throw new UnauthorizedException("User profile not found");
    }

    const normalizedRole = this.normalizeRole(userRecord["role"]);
    const permissions = await this.buildRolePermissions(orgEntityId ?? orgId, normalizedRole);
    const accessibleBranchIds = Array.isArray(
      userRecord["accessible_branch_ids"],
    )
      ? userRecord["accessible_branch_ids"].map((value: unknown) => String(value))
      : [];
    const defaultBusinessBranchId =
      userRecord["default_business_branch_id"]?.toString();
    const branchSystemId = await this.findBranchSystemId(defaultBusinessBranchId);
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
      roleLabel: userRecord["role_label"]?.toString() ?? normalizedRole,
      roleIsDefault: userRecord["role_is_default"] == true,
      accessibleBranchIds,
      defaultBusinessBranchId,
      defaultWarehouseBranchId:
        userRecord["default_warehouse_branch_id"]?.toString(),
      permissions,
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
    const orgId =
      data.user.app_metadata?.["org_id"]?.toString() ??
      data.user.user_metadata?.["org_id"]?.toString();

    if (!orgId) {
      throw new UnauthorizedException("User is not mapped to an organization");
    }

    const user = await this.buildAuthenticatedUser(data.user.id, orgId);

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
    const orgId =
      data.user.app_metadata?.["org_id"]?.toString() ??
      data.user.user_metadata?.["org_id"]?.toString();

    if (!orgId) {
      throw new UnauthorizedException("User is not mapped to an organization");
    }

    const user = await this.buildAuthenticatedUser(data.user.id, orgId);

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

    try {
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
    } catch (error) {
      // Fallback to native Supabase delivery if custom mail flow is not available.
      const { error: resetError } =
        await this.getAnonClient().auth.resetPasswordForEmail(
          email,
          normalizedRedirect ? { redirectTo: normalizedRedirect } : undefined,
        );

      if (resetError) {
        throw new UnauthorizedException(resetError.message);
      }
    }

    return { success: true };
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
    const orgId =
      data.user.app_metadata?.["org_id"]?.toString() ??
      data.user.user_metadata?.["org_id"]?.toString();

    if (!orgId) {
      throw new UnauthorizedException("User organization not found");
    }

    const user = await this.buildAuthenticatedUser(data.user.id, orgId);
    if (user.isActive != true) {
      throw new ForbiddenException("User is inactive");
    }

    return {
      sub: user.id,
      email: user.email,
      orgId: user.orgId,
      branchId: user.defaultBusinessBranchId ?? null,
      role: user.role,
      accessibleBranchIds: user.accessibleBranchIds,
      defaultBusinessBranchId: user.defaultBusinessBranchId ?? null,
      defaultWarehouseBranchId: user.defaultWarehouseBranchId ?? null,
      permissions: user.permissions,
      user,
    };
  }
}
