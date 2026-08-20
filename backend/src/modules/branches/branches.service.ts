import { BadRequestException, Inject, Injectable, forwardRef } from "@nestjs/common";
import { randomUUID } from "crypto";
import { SupabaseService } from "../supabase/supabase.service";
import { UsersService } from "../users/users.service";
import { TenantContext } from "../../common/middleware/tenant.middleware";
import { ResendService } from "../email/resend.service";
import { db, client } from "../../db/db";
import {
  users,
  settingsBranches,
  organisationBranchMaster,
  branchUserAccess,
  userBranchAccess,
  warehouses,
  settingsRoles,
  settingsBranchTransactionSeries,
} from "../../db/schema";
import { eq, and, inArray } from "drizzle-orm";

@Injectable()
export class BranchesService {
  private static readonly DEFAULT_BRANCH_INVITE_PASSWORD = "Zabnix@2025";
  private static readonly UUID_REGEX =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

  constructor(
    private readonly supabaseService: SupabaseService,
    @Inject(forwardRef(() => UsersService))
    private readonly usersService: UsersService,
    private readonly resendService: ResendService,
  ) {}

  private generateTemporaryPassword() {
    return BranchesService.DEFAULT_BRANCH_INVITE_PASSWORD;
  }

  private maskEmail(value: string): string {
    const trimmed = value.trim();
    const [localPart, domainPart] = trimmed.split("@");
    if (!localPart || !domainPart) return trimmed;
    if (localPart.length <= 2) {
      return `${localPart[0] ?? "*"}***@${domainPart}`;
    }
    return `${localPart.slice(0, 2)}***@${domainPart}`;
  }

  private escapeHtml(value: unknown): string {
    const input = String(value ?? "");
    return input
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;");
  }

  private async ensureBranchAdminUser(
    orgId: string,
    orgEntityId: string,
    email: string,
    fullName: string,
  ): Promise<string> {
    const normalizedEmail = email?.toString().trim().toLowerCase();
    if (!normalizedEmail) {
      throw new Error(
        "Branch email is required to auto-link Branch Admin user",
      );
    }

    const clientSupabase = this.supabaseService.getClient();

    const existingUsers = await db
      .select({ id: users.id, fullName: users.fullName })
      .from(users)
      .where(eq(users.email, normalizedEmail))
      .limit(1);

    const existingUser = existingUsers[0];

    if (existingUser?.id) {
      const userId = existingUser.id.toString();
      const authUpdate = await clientSupabase.auth.admin.updateUserById(userId, {
        password: this.generateTemporaryPassword(),
        user_metadata: {
          role: "branch_admin",
          org_id: orgId,
          entity_id: orgEntityId,
          full_name: fullName,
        },
        app_metadata: {
          role: "branch_admin",
          org_id: orgId,
          entity_id: orgEntityId,
        },
      });
      if (authUpdate.error) {
        throw new Error(
          `Failed to update auth user metadata: ${authUpdate.error.message}`,
        );
      }

      await db
        .update(users)
        .set({
          entityId: orgEntityId,
          fullName,
          role: "branch_admin",
          isActive: true,
          updatedAt: new Date(),
        })
        .where(eq(users.id, userId));

      return userId;
    }

    const authCreate = await clientSupabase.auth.admin.createUser({
      email: normalizedEmail,
      password: this.generateTemporaryPassword(),
      email_confirm: true,
      user_metadata: {
        full_name: fullName,
        name: fullName,
        role: "branch_admin",
        org_id: orgId,
        entity_id: orgEntityId,
      },
      app_metadata: {
        role: "branch_admin",
        org_id: orgId,
        entity_id: orgEntityId,
      },
    });

    if (authCreate.error || !authCreate.data.user?.id) {
      throw new Error(
        `Failed to create Branch Admin auth user: ${authCreate.error?.message ?? "Unknown error"}`,
      );
    }

    const userId = authCreate.data.user.id;
    await db
      .insert(users)
      .values({
        id: userId,
        entityId: orgEntityId,
        email: normalizedEmail,
        fullName,
        role: "branch_admin",
        orgId,
        isActive: true,
        updatedAt: new Date(),
      })
      .onConflictDoUpdate({
        target: users.id,
        set: {
          entityId: orgEntityId,
          fullName,
          role: "branch_admin",
          isActive: true,
          updatedAt: new Date(),
        },
      });

    return userId;
  }

  private async attachBranchAdminAccess(
    orgId: string,
    branchId: string,
    userId: string,
    roleId: string,
    options?: {
      markDefaultWarehouse?: boolean;
      defaultWarehouseId?: string | null;
    },
  ) {
    const registryEntityId = await this.resolveBranchRegistryEntityId(branchId);

    await db
      .delete(branchUserAccess)
      .where(
        and(
          eq(branchUserAccess.entityId, registryEntityId),
          eq(branchUserAccess.userId, userId),
        ),
      );

    await db.insert(branchUserAccess).values({
      entityId: registryEntityId,
      userId,
      roleId,
      isDefaultBranch: true,
      updatedAt: new Date(),
    });

    const existingLocationAccess = await db
      .select({ id: userBranchAccess.id })
      .from(userBranchAccess)
      .where(eq(userBranchAccess.userId, userId))
      .limit(1);

    const hasAnyLocation = existingLocationAccess.length > 0;
    const shouldSeedAsDefault = !hasAnyLocation;

    await db
      .insert(userBranchAccess)
      .values({
        orgId,
        userId,
        entityId: registryEntityId,
        isDefaultBusiness: shouldSeedAsDefault,
        isDefaultWarehouse:
          shouldSeedAsDefault && options?.markDefaultWarehouse === true,
        updatedAt: new Date(),
      })
      .onConflictDoUpdate({
        target: [userBranchAccess.orgId, userBranchAccess.userId, userBranchAccess.entityId],
        set: {
          isDefaultBusiness: shouldSeedAsDefault,
          isDefaultWarehouse:
            shouldSeedAsDefault && options?.markDefaultWarehouse === true,
          updatedAt: new Date(),
        },
      });
  }

  private async resolveBranchRegistryEntityId(branchId: string): Promise<string> {
    const rows = await db
      .select({ id: organisationBranchMaster.id })
      .from(organisationBranchMaster)
      .where(
        and(
          eq(organisationBranchMaster.type, "BRANCH"),
          eq(organisationBranchMaster.refId, branchId),
        ),
      )
      .limit(1);

    if (!rows[0]?.id) {
      throw new Error("Branch registry entity id not found");
    }

    return rows[0].id.toString();
  }

  private buildAutoWarehouseName(branch: any): string {
    const branchName = branch?.name?.toString().trim() ?? "";
    if (branchName.length > 0) {
      return branchName;
    }
    return "Primary Warehouse";
  }

  private buildAutoWarehouseCode(branch: any): string | null {
    const branchCode = branch?.branch_code?.toString().trim() ?? "";
    if (branchCode.length === 0) {
      return null;
    }
    return `${branchCode}-WH`;
  }

  private async ensureDefaultWarehouseForBranch(
    orgId: string,
    branch: any,
  ): Promise<string | null> {
    const branchId = branch?.id?.toString().trim() ?? "";
    if (!branchId) {
      throw new Error("Cannot provision warehouse for branch without id");
    }

    const existingRows = await db
      .select({ id: warehouses.id })
      .from(warehouses)
      .where(
        and(
          eq(warehouses.orgId, orgId),
          eq(warehouses.sourceBranchId, branchId),
        ),
      )
      .limit(1);

    const existingWarehouse = existingRows[0];
    if (existingWarehouse?.id) {
      return existingWarehouse.id.toString();
    }

    const registryEntityId = await this.resolveBranchRegistryEntityId(branchId);
    const [data] = await db
      .insert(warehouses)
      .values({
        entityId: registryEntityId,
        orgId,
        sourceBranchId: branchId,
        name: this.buildAutoWarehouseName(branch),
        warehouseCode: this.buildAutoWarehouseCode(branch),
        attention: branch?.attention ?? null,
        street: branch?.street ?? null,
        place: branch?.place ?? null,
        city: branch?.city ?? null,
        state: branch?.state ?? null,
        districtId: this.normalizeUuid(branch?.district_id),
        localBodyId: this.normalizeUuid(branch?.local_body_id),
        assemblyId: this.normalizeUuid(branch?.assembly_id),
        wardId: this.normalizeUuid(branch?.ward_id),
        pincode: branch?.pincode ?? null,
        country: branch?.country ?? "India",
        phone: branch?.phone ?? null,
        email: branch?.email ?? null,
        isActive: branch?.is_active ?? true,
      })
      .returning();

    return data?.id?.toString() ?? null;
  }

  private async ensureOrganisationMaster(orgId: string) {
    const normalizedOrgId = this.normalizeUuid(orgId);
    if (!normalizedOrgId) return null;

    const existingRes = await db
      .select({ id: organisationBranchMaster.id })
      .from(organisationBranchMaster)
      .where(
        and(
          eq(organisationBranchMaster.type, "ORG"),
          eq(organisationBranchMaster.refId, normalizedOrgId),
        ),
      )
      .limit(1);

    if (existingRes[0]?.id) {
      return existingRes[0].id.toString();
    }

    const orgRes = await client.unsafe(
      `SELECT id, name, is_active FROM organization WHERE id = $1 LIMIT 1`,
      [normalizedOrgId],
    );

    if (!orgRes[0]?.id || !orgRes[0]?.name) {
      return null;
    }

    const [upserted] = await db
      .insert(organisationBranchMaster)
      .values({
        name: orgRes[0].name,
        type: "ORG",
        refId: orgRes[0].id,
        parentId: null,
        isActive: orgRes[0].is_active ?? true,
      })
      .onConflictDoUpdate({
        target: [organisationBranchMaster.type, organisationBranchMaster.refId],
        set: {
          name: orgRes[0].name,
          isActive: orgRes[0].is_active ?? true,
        },
      })
      .returning();

    return upserted?.id?.toString() ?? null;
  }

  private async syncOrganisationBranchMasterRow(branch: {
    id: string;
    org_id: string;
    name: string;
    is_active?: boolean | null;
  }) {
    const parentId = await this.ensureOrganisationMaster(branch.org_id);

    await db
      .insert(organisationBranchMaster)
      .values({
        name: branch.name,
        type: "BRANCH",
        refId: branch.id,
        parentId,
        isActive: branch.is_active ?? true,
      })
      .onConflictDoUpdate({
        target: [organisationBranchMaster.type, organisationBranchMaster.refId],
        set: {
          name: branch.name,
          parentId,
          isActive: branch.is_active ?? true,
        },
      });
  }

  private async removeOrganisationBranchMasterRow(branchId: string) {
    await db
      .delete(organisationBranchMaster)
      .where(
        and(
          eq(organisationBranchMaster.type, "BRANCH"),
          eq(organisationBranchMaster.refId, branchId),
        ),
      );
  }

  private normalizeBranchType(value: unknown) {
    return value?.toString().trim().toUpperCase() || null;
  }

  private normalizeUuid(value: unknown) {
    const normalized = value?.toString().trim();
    if (!normalized) return null;
    return BranchesService.UUID_REGEX.test(normalized) ? normalized : null;
  }

  private normalizeUuidList(values: unknown): string[] {
    if (!Array.isArray(values)) return [];
    return Array.from(
      new Set(
        values
          .map((value) => this.normalizeUuid(value))
          .filter((value): value is string => Boolean(value)),
      ),
    );
  }

  private normalizeLocationUsers(values: unknown) {
    if (!Array.isArray(values))
      return [] as Array<{
        user_id: string;
        role: string | null;
      }>;

    const seen = new Set<string>();
    return values
      .map((value) => {
        const userId = this.normalizeUuid(value?.user_id);
        if (!userId || seen.has(userId)) return null;
        seen.add(userId);
        const role = value?.role?.toString().trim() || null;
        return { user_id: userId, role };
      })
      .filter(
        (
          value,
        ): value is {
          user_id: string;
          role: string | null;
        } => Boolean(value),
      );
  }

  private parseJsonObject(rawValue?: string | null) {
    if (!rawValue?.trim()) {
      return null as Record<string, any> | null;
    }

    try {
      const parsed = JSON.parse(rawValue);
      return parsed && typeof parsed === "object" && !Array.isArray(parsed)
        ? (parsed as Record<string, any>)
        : null;
    } catch {
      return null;
    }
  }

  private parseBranchCodeTemplate(rawCode?: string | null) {
    const normalized = rawCode?.toString().trim();
    if (!normalized) {
      return { prefix: "BR-", padLength: 5 };
    }
    const match = normalized.match(/^(.*?)(\d+)$/);
    if (!match) {
      return { prefix: normalized, padLength: 5 };
    }
    return {
      prefix: match[1] ?? "BR-",
      padLength: (match[2] ?? "").length || 5,
    };
  }

  private async generateNextBranchCode(
    orgId: string,
    prefix: string,
    padLength: number,
  ) {
    const rows = await db
      .select({ branchCode: settingsBranches.branchCode })
      .from(settingsBranches)
      .where(eq(settingsBranches.orgId, orgId));

    let maxValue = 0;
    for (const row of rows ?? []) {
      const code = row?.branchCode?.toString().trim();
      if (!code || !code.startsWith(prefix)) continue;
      const suffix = code.substring(prefix.length);
      const numeric = parseInt(suffix, 10);
      if (!Number.isNaN(numeric) && numeric > maxValue) {
        maxValue = numeric;
      }
    }

    const nextValue = maxValue + 1;
    return `${prefix}${nextValue.toString().padStart(padLength, "0")}`;
  }

  private async resolveAssemblyId(
    _districtId?: string | null,
    _assemblyCodeOrName?: string | null,
  ) {
    return null;
  }

  private async hydratePaymentStubAssembly(
    rawAddress?: string | null,
    assemblyId?: string | null,
  ) {
    if (!rawAddress?.trim() || !assemblyId?.trim()) {
      return rawAddress ?? null;
    }

    const parsed = this.parseJsonObject(rawAddress);
    if (!parsed) {
      return rawAddress;
    }

    try {
      const rows = await client.unsafe(
        `SELECT id, code, name FROM assemblies_constituencies WHERE id = $1 LIMIT 1`,
        [assemblyId.trim()],
      );
      const data = rows[0];
      if (!data) return rawAddress;

      parsed["assembly_code"] = data.code ?? parsed["assembly_code"] ?? null;
      parsed["assembly_name"] = data.name ?? parsed["assembly_name"] ?? null;
      return JSON.stringify(parsed);
    } catch {
      return rawAddress;
    }
  }

  private async resolveBranchAccessRoleIds(
    entityId: string,
    locationUsers: Array<{ user_id: string; role: string | null }>,
  ) {
    const roleLabels = Array.from(
      new Set(
        locationUsers
          .map((user) => user.role?.trim())
          .filter((role): role is string => Boolean(role)),
      ),
    );

    if (roleLabels.length === 0) {
      return new Map<string, string | null>();
    }

    const data = await db
      .select({ id: settingsRoles.id, label: settingsRoles.label })
      .from(settingsRoles)
      .where(
        and(
          eq(settingsRoles.entityId, entityId),
          eq(settingsRoles.isActive, true),
          inArray(settingsRoles.label, roleLabels),
        ),
      );

    const roleIdMap = new Map<string, string | null>();
    for (const role of roleLabels) {
      roleIdMap.set(role, null);
    }

    roleIdMap.set("Admin", "admin");
    roleIdMap.set("HO Admin", "ho_admin");
    roleIdMap.set("Branch Admin", "branch_admin");

    for (const row of data ?? []) {
      const label = row.label?.toString().trim();
      const id = row.id?.toString().trim();
      if (label && id) {
        roleIdMap.set(label, id);
      }
    }

    return roleIdMap;
  }

  private async syncTransactionSeries(
    entityId: string,
    transactionSeriesIds: string[],
  ) {
    await db
      .delete(settingsBranchTransactionSeries)
      .where(eq(settingsBranchTransactionSeries.entityId, entityId));

    if (transactionSeriesIds.length === 0) return;

    await db.insert(settingsBranchTransactionSeries).values(
      transactionSeriesIds.map((transactionSeriesId) => ({
        entityId,
        transactionSeriesId,
      })),
    );
  }

  private async syncLocationUsers(
    entityId: string,
    locationUsers: Array<{ user_id: string; role: string | null }>,
  ) {
    const roleIdsByLabel = await this.resolveBranchAccessRoleIds(
      entityId,
      locationUsers,
    );

    await db
      .delete(branchUserAccess)
      .where(eq(branchUserAccess.entityId, entityId));

    if (locationUsers.length === 0) return;

    await db.insert(branchUserAccess).values(
      locationUsers.map((user) => ({
        entityId,
        userId: user.user_id,
        roleId: user.role ? (roleIdsByLabel.get(user.role) ?? null) : null,
      })),
    );
  }

  private async attachRelations(branch: any) {
    if (!branch?.id) return branch;

    const obmRows = await db
      .select({ id: organisationBranchMaster.id })
      .from(organisationBranchMaster)
      .where(
        and(
          eq(organisationBranchMaster.refId, branch.id),
          eq(organisationBranchMaster.type, "BRANCH"),
        ),
      )
      .limit(1);

    const entityId = obmRows[0]?.id ?? null;

    if (!entityId) {
      return { ...branch, transaction_series_ids: [], location_users: [] };
    }

    const [transactionSeriesRes, locationUsersRes] = await Promise.all([
      db
        .select({
          transactionSeriesId: settingsBranchTransactionSeries.transactionSeriesId,
        })
        .from(settingsBranchTransactionSeries)
        .where(eq(settingsBranchTransactionSeries.entityId, entityId)),
      db
        .select({
          userId: branchUserAccess.userId,
          roleId: branchUserAccess.roleId,
        })
        .from(branchUserAccess)
        .where(eq(branchUserAccess.entityId, entityId)),
    ]);

    const transactionSeriesIds = (transactionSeriesRes ?? [])
      .map((row) => row.transactionSeriesId?.toString())
      .filter((value: unknown): value is string => Boolean(value));

    const assignedUserIds = (locationUsersRes ?? [])
      .map((row) => row.userId?.toString())
      .filter((value: unknown): value is string => Boolean(value));

    const assignedRoleIds = (locationUsersRes ?? [])
      .map((row) => row.roleId?.toString())
      .filter((value: unknown): value is string => Boolean(value));

    const usersRes =
      assignedUserIds.length > 0
        ? await db
            .select({ id: users.id, role: users.role })
            .from(users)
            .where(inArray(users.id, assignedUserIds))
        : [];

    const userDefaultRoleIds = usersRes
      .map((row) => row.role?.toString())
      .filter(
        (value: unknown): value is string =>
          typeof value === "string" &&
          value.length > 0 &&
          !["admin", "ho_admin", "branch_admin"].includes(value),
      );

    const allRoleIds = Array.from(
      new Set([...assignedRoleIds, ...userDefaultRoleIds]),
    );

    const rolesRes =
      allRoleIds.length > 0
        ? await db
            .select({ id: settingsRoles.id, label: settingsRoles.label })
            .from(settingsRoles)
            .where(inArray(settingsRoles.id, allRoleIds))
        : [];

    const roleLabelMap = new Map(
      rolesRes.map((row) => [row.id?.toString(), row.label?.toString() ?? null]),
    );

    roleLabelMap.set("admin", "Admin");
    roleLabelMap.set("ho_admin", "HO Admin");
    roleLabelMap.set("branch_admin", "Branch Admin");

    const userRoleMap = new Map(
      usersRes.map((row) => {
        const rId = row.role?.toString() ?? null;
        return [
          row.id?.toString(),
          rId ? (roleLabelMap.get(rId) ?? rId) : null,
        ];
      }),
    );

    return {
      ...branch,
      payment_stub_address: await this.hydratePaymentStubAssembly(
        branch.payment_stub_address,
        branch.payment_stub_assembly_id,
      ),
      transaction_series_ids: transactionSeriesIds,
      transaction_series_id:
        transactionSeriesIds.length > 0 ? transactionSeriesIds[0] : null,
      location_users: (locationUsersRes ?? []).map((row) => ({
        user_id: row.userId?.toString(),
        role:
          roleLabelMap.get(row.roleId?.toString() ?? "") ??
          userRoleMap.get(row.userId?.toString() ?? "") ??
          null,
        role_id: row.roleId?.toString() ?? null,
      })),
    };
  }

  async findBusinessTypes(_tenant: TenantContext) {
    try {
      const data = await client.unsafe(
        `SELECT code, label, description, sort_order FROM business_types WHERE is_active = true ORDER BY sort_order ASC, label ASC`,
      );

      return (data ?? []).map((row: any) => ({
        id: row.code?.toString() ?? "",
        code: row.code?.toString() ?? "",
        label: row.label?.toString() ?? "",
        description: row.description?.toString() ?? "",
        sort_order: row.sort_order ?? 0,
      }));
    } catch (err) {
      throw new Error(`Failed to fetch business_types: ${(err as Error).message}`);
    }
  }

  async createBusinessType(dto: any) {
    const businessType = this.normalizeBranchType(
      dto.business_type ?? dto.code,
    );
    const label =
      dto.label?.toString().trim() || dto.description?.toString().trim();

    if (!businessType) {
      throw new Error("Business type code is required");
    }
    if (!label) {
      throw new Error("Business type label is required");
    }

    try {
      const rows = await client.unsafe(
        `INSERT INTO business_types (code, label, description, is_active) VALUES ($1, $2, $3, true) RETURNING code, label, description, sort_order`,
        [businessType, label, dto.description?.toString().trim() ?? ""],
      );

      const data = rows[0];
      return {
        id: data.code?.toString() ?? "",
        code: data.code?.toString() ?? "",
        label: data.label?.toString() ?? "",
        description: data.description?.toString() ?? "",
        sort_order: data.sort_order ?? 0,
      };
    } catch (err) {
      throw new Error(`Failed to create business type: ${(err as Error).message}`);
    }
  }

  private resolveTenant(tenantOrOrgId: TenantContext | string): {
    orgId: string;
    entityId?: string | null;
  } {
    if (typeof tenantOrOrgId === "string") {
      return { orgId: tenantOrOrgId };
    }
    return { orgId: tenantOrOrgId.orgId, entityId: tenantOrOrgId.entityId };
  }

  async findAll(tenantOrOrgId: TenantContext | string) {
    const tenant =
      typeof tenantOrOrgId === "string"
        ? null
        : (tenantOrOrgId as TenantContext);
    const { orgId } = this.resolveTenant(tenantOrOrgId);

    const scopedBranchIds = tenant?.accessibleBranchIds ?? [];

    try {
      let sqlQuery = `
        SELECT b.*, obm.id as entity_id
        FROM branches b
        LEFT JOIN organisation_branch_master obm ON obm.ref_id = b.id AND obm.type = 'BRANCH'
        WHERE b.org_id = $1
      `;
      const params: any[] = [orgId];

      if (tenant && tenant.role !== "admin" && scopedBranchIds.length > 0) {
        params.push(scopedBranchIds);
        sqlQuery += ` AND b.id = ANY($2)`;
      }

      sqlQuery += ` ORDER BY b.created_at ASC`;

      const data = await client.unsafe(sqlQuery, params);
      return data ?? [];
    } catch (err) {
      throw new Error(`Failed to fetch branches: ${(err as Error).message}`);
    }
  }

  async findOne(id: string, tenantOrOrgId: TenantContext | string) {
    const { orgId } = this.resolveTenant(tenantOrOrgId);
    try {
      const rows = await client.unsafe(
        `SELECT * FROM branches WHERE id = $1 AND org_id = $2 LIMIT 1`,
        [id, orgId],
      );

      const data = rows[0];
      if (!data) return null;
      return this.attachRelations(data);
    } catch {
      return null;
    }
  }

  async create(dto: any, tenant: TenantContext) {
    const orgId = tenant.orgId;
    const normalizedPhone = dto.phone?.toString().trim();
    if (normalizedPhone) {
      const mobileRegex = /^[0-9]{10}$/;
      if (!mobileRegex.test(normalizedPhone)) {
        throw new BadRequestException("Phone number must be exactly 10 digits.");
      }
    }

    const transactionSeriesIds = this.normalizeUuidList(
      dto.transaction_series_ids,
    );
    const locationUsers = this.normalizeLocationUsers(dto.location_users);
    const hasSeparatePaymentStubAddress =
      dto.has_separate_payment_stub_address ?? false;
    const paymentStubAddress =
      typeof dto.payment_stub_address === "string"
        ? dto.payment_stub_address
        : null;
    const parsedPaymentStubAddress =
      this.parseJsonObject(paymentStubAddress) ?? undefined;
    const assemblyMatch = hasSeparatePaymentStubAddress
      ? await this.resolveAssemblyId(
          parsedPaymentStubAddress?.district_id?.toString(),
          parsedPaymentStubAddress?.assembly_code?.toString() ??
            parsedPaymentStubAddress?.assembly_name?.toString(),
        )
      : null;

    const parentId = await this.ensureOrganisationMaster(orgId);
    const newBranchId = randomUUID();

    await db
      .insert(organisationBranchMaster)
      .values({
        name: dto.name,
        type: "BRANCH",
        refId: newBranchId,
        parentId,
        isActive: dto.is_active ?? true,
      })
      .onConflictDoUpdate({
        target: [organisationBranchMaster.type, organisationBranchMaster.refId],
        set: {
          name: dto.name,
          parentId,
          isActive: dto.is_active ?? true,
        },
      });

    const codeTemplate = this.parseBranchCodeTemplate(dto.branch_code);
    let branchCodeToUse = dto.branch_code?.toString().trim() || null;
    if (!branchCodeToUse) {
      branchCodeToUse = await this.generateNextBranchCode(
        orgId,
        codeTemplate.prefix,
        codeTemplate.padLength,
      );
    }

    const insertBranch = async (code: string | null) =>
      db
        .insert(settingsBranches)
        .values({
          id: newBranchId,
          orgId,
          name: dto.name,
          branchCode: code,
          branchType: this.normalizeBranchType(dto.branch_type) as any,
          email: dto.email ?? null,
          phone: dto.phone ?? null,
          website: dto.website ?? null,
          attention: dto.attention ?? null,
          street: dto.street ?? null,
          place: dto.place ?? null,
          city: dto.city ?? null,
          state: dto.state ?? null,
          districtId: this.normalizeUuid(dto.district_id),
          localBodyId: this.normalizeUuid(dto.local_body_id),
          assemblyId: this.normalizeUuid(dto.assembly_id),
          wardId: this.normalizeUuid(dto.ward_id),
          pincode: dto.pincode ?? null,
          country: dto.country ?? "India",
          isChildLocation: dto.is_child_location ?? false,
          parentBranchId: this.normalizeUuid(dto.parent_branch_id),
          primaryContactId: this.normalizeUuid(dto.primary_contact_id),
          gstin: dto.gstin ?? null,
          gstinRegistrationType: dto.gstin_registration_type ?? null,
          gstinLegalName: dto.gstin_legal_name ?? null,
          gstinTradeName: dto.gstin_trade_name ?? null,
          gstinRegisteredOn: dto.gstin_registered_on ?? null,
          gstinReverseCharge: dto.gstin_reverse_charge ?? false,
          gstinImportExport: dto.gstin_import_export ?? false,
          gstinImportExportAccountId: this.normalizeUuid(
            dto.gstin_import_export_account_id,
          ),
          gstinDigitalServices: dto.gstin_digital_services ?? false,
          gstTreatment: dto.gst_treatment ?? null,
          pan: dto.pan ?? null,
          industry: dto.industry ?? null,
          isDrugRegistered: dto.is_drug_registered ?? false,
          drugLicenceType: dto.drug_licence_type ?? null,
          drugLicence20: dto.drug_licence_20 ?? dto.drug_license_20 ?? null,
          drugLicence21: dto.drug_licence_21 ?? dto.drug_license_21 ?? null,
          drugLicence20b: dto.drug_licence_20b ?? dto.drug_license_20b ?? null,
          drugLicence21b: dto.drug_licence_21b ?? dto.drug_license_21b ?? null,
          isFssaiRegistered: dto.is_fssai_registered ?? false,
          fssaiNumber: dto.fssai_number ?? null,
          isMsmeRegistered: dto.is_msme_registered ?? false,
          msmeRegistrationType:
            dto.msme_registration_type ?? dto.msme_type ?? null,
          msmeNumber: dto.msme_number ?? null,
          msmeType: dto.msme_type ?? dto.msme_registration_type ?? null,
          fiscalYear: dto.fiscal_year ?? null,
          reportBasis: dto.report_basis ?? null,
          hasSeparatePaymentStubAddress,
          paymentStubAddress,
          paymentStubAssemblyId: (assemblyMatch as any)?.id ?? null,
          logoUrl: dto.logo_url ?? null,
          subscriptionFrom: dto.subscription_from ?? null,
          subscriptionTo: dto.subscription_to ?? null,
          defaultTransactionSeriesId: this.normalizeUuid(
            dto.default_transaction_series_id,
          ),
          isActive: dto.is_active ?? true,
        })
        .returning();

    let insertedRows;
    try {
      insertedRows = await insertBranch(branchCodeToUse);
    } catch {
      branchCodeToUse = await this.generateNextBranchCode(
        orgId,
        codeTemplate.prefix,
        codeTemplate.padLength,
      );
      insertedRows = await insertBranch(branchCodeToUse);
    }

    const data = insertedRows[0];

    let defaultWarehouseId: string | null = null;
    try {
      defaultWarehouseId = await this.ensureDefaultWarehouseForBranch(
        orgId,
        data,
      );
    } catch (warehouseError) {
      console.error(
        "[Branches] default warehouse auto-provision failed after branch create:",
        warehouseError,
      );
    }

    const branchEmail = dto.email?.toString().trim();
    const branchName = dto.name?.toString().trim() ?? "";
    const attentionName = dto.attention?.toString().trim() ?? "";
    const fullName = attentionName || branchName || "Branch Admin";
    const orgEntityId = tenant.entityId ?? parentId;

    let branchAdminRoleId: string | null = null;
    try {
      const roles = await this.usersService.ensureCoreDefaultRoles(tenant);
      branchAdminRoleId = roles.branchAdminRoleId ?? null;
    } catch (roleError) {
      console.error(
        "[Branches] ensureCoreDefaultRoles failed after branch create:",
        roleError,
      );
    }

    if (branchEmail && branchAdminRoleId && orgEntityId) {
      try {
        const branchAdminUserId = await this.ensureBranchAdminUser(
          orgId,
          orgEntityId,
          branchEmail,
          fullName,
        );
        await this.attachBranchAdminAccess(
          orgId,
          data.id,
          branchAdminUserId,
          branchAdminRoleId,
          {
            markDefaultWarehouse: defaultWarehouseId != null,
            defaultWarehouseId,
          },
        );
      } catch (accessError) {
        console.error(
          "[Branches] branch admin auto-link failed after branch create:",
          accessError,
        );
      }
    }

    if (branchEmail) {
      try {
        const loginUrl =
          process.env.FRONTEND_APP_URL?.trim() ||
          process.env.APP_LOGIN_URL?.trim() ||
          "https://zerpai--erp.web.app/";
        const defaultPassword = this.generateTemporaryPassword();
        const branchCode = data.branchCode ?? dto.branch_code ?? "—";
        const branchSystemId = data.systemId ?? "—";

        await this.resendService.sendEmail({
          to: branchEmail,
          subject: `Branch invitation · ${branchName || "Zerpai ERP"}`,
          html: `
            <div style="font-family: sans-serif; line-height: 1.5; color: #333;">
              <h2>Welcome to Zerpai ERP</h2>
              <p>Hello <strong>${this.escapeHtml(fullName)}</strong>,</p>
              <p>Your account has been linked to a new branch in Zerpai ERP.</p>
              <div style="background: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p style="margin: 0;"><strong>Branch Name:</strong> ${this.escapeHtml(branchName || "—")}</p>
                <p style="margin: 5px 0;"><strong>Branch Code:</strong> ${this.escapeHtml(branchCode)}</p>
                <p style="margin: 5px 0;"><strong>System ID:</strong> ${this.escapeHtml(branchSystemId)}</p>
                <p style="margin: 5px 0;"><strong>Email:</strong> ${this.escapeHtml(branchEmail)}</p>
                <p style="margin: 0;"><strong>Default Password:</strong> <code style="background: #eee; padding: 2px 4px;">${this.escapeHtml(defaultPassword)}</code></p>
              </div>
              <p><a href="${loginUrl}" style="background-color: #0088FF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold;">Click here to Login</a></p>
            </div>
          `,
        });
      } catch (emailError) {
        console.error(
          `[Branches] failed to send branch creation email -> branch_id=${data.id}`,
          emailError,
        );
      }
    }

    try {
      await this.syncOrganisationBranchMasterRow({
        id: data.id,
        org_id: orgId,
        name: data.name,
        is_active: data.isActive,
      });
    } catch (syncMasterError) {
      console.error(
        "[Branches] organisation_branch_master sync failed after branch create:",
        syncMasterError,
      );
    }
    if (tenant.entityId) {
      try {
        await this.syncTransactionSeries(tenant.entityId, transactionSeriesIds);
      } catch (syncSeriesError) {
        console.error(
          "[Branches] transaction series sync failed after branch create:",
          syncSeriesError,
        );
      }
      try {
        await this.syncLocationUsers(tenant.entityId, locationUsers);
      } catch (syncUsersError) {
        console.error(
          "[Branches] location users sync failed after branch create:",
          syncUsersError,
        );
      }
    }

    return this.findOne(data.id, tenant);
  }

  async update(id: string, tenant: TenantContext, dto: any) {
    const orgId = tenant.orgId;
    if (dto.phone) {
      const mobileRegex = /^[0-9]{10}$/;
      if (!mobileRegex.test(dto.phone.toString().trim())) {
        throw new BadRequestException("Phone number must be exactly 10 digits.");
      }
    }

    const updatePayload: Record<string, any> = { updatedAt: new Date() };

    if ("name" in dto) updatePayload.name = dto.name;
    if ("branch_code" in dto) updatePayload.branchCode = dto.branch_code;
    if ("branch_type" in dto) updatePayload.branchType = this.normalizeBranchType(dto.branch_type);
    if ("email" in dto) updatePayload.email = dto.email;
    if ("phone" in dto) updatePayload.phone = dto.phone;
    if ("website" in dto) updatePayload.website = dto.website;
    if ("attention" in dto) updatePayload.attention = dto.attention;
    if ("street" in dto) updatePayload.street = dto.street;
    if ("place" in dto) updatePayload.place = dto.place;
    if ("city" in dto) updatePayload.city = dto.city;
    if ("state" in dto) updatePayload.state = dto.state;
    if ("district_id" in dto) updatePayload.districtId = this.normalizeUuid(dto.district_id);
    if ("local_body_id" in dto) updatePayload.localBodyId = this.normalizeUuid(dto.local_body_id);
    if ("assembly_id" in dto) updatePayload.assemblyId = this.normalizeUuid(dto.assembly_id);
    if ("ward_id" in dto) updatePayload.wardId = this.normalizeUuid(dto.ward_id);
    if ("pincode" in dto) updatePayload.pincode = dto.pincode;
    if ("country" in dto) updatePayload.country = dto.country;
    if ("is_child_location" in dto) updatePayload.isChildLocation = dto.is_child_location;
    if ("parent_branch_id" in dto) updatePayload.parentBranchId = this.normalizeUuid(dto.parent_branch_id);
    if ("primary_contact_id" in dto) updatePayload.primaryContactId = this.normalizeUuid(dto.primary_contact_id);
    if ("gstin" in dto) updatePayload.gstin = dto.gstin;
    if ("gstin_registration_type" in dto) updatePayload.gstinRegistrationType = dto.gstin_registration_type;
    if ("gstin_legal_name" in dto) updatePayload.gstinLegalName = dto.gstin_legal_name;
    if ("gstin_trade_name" in dto) updatePayload.gstinTradeName = dto.gstin_trade_name;
    if ("gstin_registered_on" in dto) updatePayload.gstinRegisteredOn = dto.gstin_registered_on;
    if ("gstin_reverse_charge" in dto) updatePayload.gstinReverseCharge = dto.gstin_reverse_charge;
    if ("gstin_import_export" in dto) updatePayload.gstinImportExport = dto.gstin_import_export;
    if ("gstin_import_export_account_id" in dto) updatePayload.gstinImportExportAccountId = this.normalizeUuid(dto.gstin_import_export_account_id);
    if ("gstin_digital_services" in dto) updatePayload.gstinDigitalServices = dto.gstin_digital_services;
    if ("gst_treatment" in dto) updatePayload.gstTreatment = dto.gst_treatment;
    if ("pan" in dto) updatePayload.pan = dto.pan;
    if ("industry" in dto) updatePayload.industry = dto.industry;
    if ("is_drug_registered" in dto) updatePayload.isDrugRegistered = dto.is_drug_registered;
    if ("drug_licence_type" in dto) updatePayload.drugLicenceType = dto.drug_licence_type;
    if ("drug_licence_20" in dto) updatePayload.drugLicence20 = dto.drug_licence_20 || null;
    if ("drug_licence_21" in dto) updatePayload.drugLicence21 = dto.drug_licence_21 || null;
    if ("drug_licence_20b" in dto) updatePayload.drugLicence20b = dto.drug_licence_20b || null;
    if ("drug_licence_21b" in dto) updatePayload.drugLicence21b = dto.drug_licence_21b || null;
    if ("is_fssai_registered" in dto) updatePayload.isFssaiRegistered = dto.is_fssai_registered;
    if ("fssai_number" in dto) updatePayload.fssaiNumber = dto.fssai_number;
    if ("is_msme_registered" in dto) updatePayload.isMsmeRegistered = dto.is_msme_registered;
    if ("msme_registration_type" in dto) updatePayload.msmeRegistrationType = dto.msme_registration_type;
    if ("msme_number" in dto) updatePayload.msmeNumber = dto.msme_number;
    if ("msme_type" in dto) updatePayload.msmeType = dto.msme_type;
    if ("fiscal_year" in dto) updatePayload.fiscalYear = dto.fiscal_year;
    if ("report_basis" in dto) updatePayload.reportBasis = dto.report_basis;
    if ("has_separate_payment_stub_address" in dto) updatePayload.hasSeparatePaymentStubAddress = Boolean(dto.has_separate_payment_stub_address);
    if ("payment_stub_address" in dto) updatePayload.paymentStubAddress = dto.payment_stub_address;
    if ("logo_url" in dto) updatePayload.logoUrl = dto.logo_url;
    if ("subscription_from" in dto) updatePayload.subscriptionFrom = dto.subscription_from;
    if ("subscription_to" in dto) updatePayload.subscriptionTo = dto.subscription_to;
    if ("default_transaction_series_id" in dto) updatePayload.defaultTransactionSeriesId = this.normalizeUuid(dto.default_transaction_series_id);
    if ("is_active" in dto) updatePayload.isActive = dto.is_active;

    const [data] = await db
      .update(settingsBranches)
      .set(updatePayload)
      .where(and(eq(settingsBranches.id, id), eq(settingsBranches.orgId, orgId)))
      .returning();

    if (!data) throw new Error("Branch not found or failed to update");

    await this.syncOrganisationBranchMasterRow({
      id: data.id,
      org_id: orgId,
      name: data.name,
      is_active: data.isActive,
    });

    if ("transaction_series_ids" in dto && tenant.entityId) {
      await this.syncTransactionSeries(
        tenant.entityId,
        this.normalizeUuidList(dto.transaction_series_ids),
      );
    }

    if ("location_users" in dto && tenant.entityId) {
      await this.syncLocationUsers(
        tenant.entityId,
        this.normalizeLocationUsers(dto.location_users),
      );
    }

    return this.findOne(data.id, tenant);
  }

  async remove(id: string, tenant: TenantContext) {
    await db
      .delete(settingsBranches)
      .where(
        and(
          eq(settingsBranches.id, id),
          eq(settingsBranches.orgId, tenant.orgId),
        ),
      );

    await this.removeOrganisationBranchMasterRow(id);
    return { success: true };
  }
}
