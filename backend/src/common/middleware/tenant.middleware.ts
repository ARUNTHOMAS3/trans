import {
  ForbiddenException,
  Injectable,
  NestMiddleware,
  UnauthorizedException,
} from "@nestjs/common";
import { Request, Response, NextFunction } from "express";
import { AuthService } from "../auth/auth.service";
import { SupabaseService } from "../../modules/supabase/supabase.service";

export interface TenantContext {
  userId: string;
  email: string;
  orgId: string;
  branchId: string | null;
  entityId: string | null; // Added for Polymorphic Entity Refactor
  role: string;
  accessibleBranchIds: string[];
  defaultBusinessBranchId: string | null;
  defaultWarehouseBranchId: string | null;
  permissions: Record<string, unknown> | null;
  user?: Record<string, unknown>;
}

interface ApiPermissionRule {
  prefix: string;
  moduleKey: string;
}

// Extend Express Request to include tenant context
declare module "express-serve-static-core" {
  interface Request {
    tenantContext?: TenantContext;
  }
}

@Injectable()
export class TenantMiddleware implements NestMiddleware {
  constructor(
    private authService: AuthService,
    private supabaseService: SupabaseService,
  ) {}

  private static readonly adminOnlyModules = new Set<string>([
    "users_roles",
    "audit_logs",
  ]);

  private static readonly moduleAliases: Record<string, string[]> = {
    shipments: ["sales_shipments"],
    sales_shipments: ["shipments"],
    ewaybill_perms: ["ewaybill_settings"],
    ewaybill_settings: ["ewaybill_perms"],
  };

  private static readonly apiPermissionRules: ApiPermissionRule[] = [
    { prefix: "/api/v1/reports/audit-logs", moduleKey: "audit_logs" },
    { prefix: "/api/v1/reports", moduleKey: "reports" },

    { prefix: "/api/v1/users/roles", moduleKey: "users_roles" },
    { prefix: "/api/v1/users", moduleKey: "users_roles" },

    { prefix: "/api/v1/branches", moduleKey: "branches" },
    { prefix: "/api/v1/warehouses-settings", moduleKey: "warehouses" },
    { prefix: "/api/v1/zones", moduleKey: "zones" },

    { prefix: "/api/v1/products/composite", moduleKey: "composite_items" },
    { prefix: "/api/v1/products", moduleKey: "item" },
    { prefix: "/api/v1/branch_inventory", moduleKey: "inventory_adjustments" },
    { prefix: "/api/v1/picklists", moduleKey: "picklists" },
    { prefix: "/api/v1/packages", moduleKey: "packages" },
    { prefix: "/api/v1/shipments", moduleKey: "shipments" },
    { prefix: "/api/v1/transfer-orders", moduleKey: "transfer_orders" },
    { prefix: "/api/v1/price-lists", moduleKey: "price_list" },

    { prefix: "/api/v1/sales/customers", moduleKey: "customers" },
    { prefix: "/api/v1/sales/quotations", moduleKey: "quotations" },
    { prefix: "/api/v1/sales/invoices", moduleKey: "invoices" },
    { prefix: "/api/v1/sales/delivery-challans", moduleKey: "delivery_challans" },
    { prefix: "/api/v1/sales/payments-received", moduleKey: "customer_payments" },
    { prefix: "/api/v1/sales/credit-notes", moduleKey: "credit_notes" },
    { prefix: "/api/v1/sales/e-way-bills", moduleKey: "ewaybill_perms" },
    { prefix: "/api/v1/sales/payment-links", moduleKey: "payment_links" },
    { prefix: "/api/v1/sales/recurring-invoices", moduleKey: "recurring_invoices" },
    { prefix: "/api/v1/sales/returns", moduleKey: "sales_returns" },
    { prefix: "/api/v1/sales/retainer-invoices", moduleKey: "retainer_invoices" },
    { prefix: "/api/v1/sales", moduleKey: "sales_orders" },

    { prefix: "/api/v1/vendors", moduleKey: "vendors" },
    { prefix: "/api/v1/expenses", moduleKey: "expenses" },
    { prefix: "/api/v1/purchase-orders", moduleKey: "purchase_orders" },
    { prefix: "/api/v1/purchase-receives", moduleKey: "purchase_receives" },
    { prefix: "/api/v1/bills", moduleKey: "bills" },

    { prefix: "/api/v1/accountant/journal-templates", moduleKey: "journal_templates" },
    { prefix: "/api/v1/accountant/manual-journals", moduleKey: "manual_journals" },
    { prefix: "/api/v1/accountant/recurring-journals", moduleKey: "recurring_journals" },
    { prefix: "/api/v1/accountant/transaction-locking", moduleKey: "transaction_locking" },
    { prefix: "/api/v1/accountant/transactions", moduleKey: "account_transactions" },
    { prefix: "/api/v1/accountant/opening-balances", moduleKey: "opening_balances" },
    { prefix: "/api/v1/accountant", moduleKey: "chart_of_accounts" },

    { prefix: "/api/v1/transaction-locking", moduleKey: "transaction_locking" },
    { prefix: "/api/v1/transaction-series", moduleKey: "transaction_series" },
    { prefix: "/api/v1/sequences", moduleKey: "transaction_series" },
    { prefix: "/api/v1/currencies", moduleKey: "general_prefs" },
    { prefix: "/api/v1/gst", moduleKey: "general_prefs" },
  ];

  private isAuthEnabled() {
    return process.env.ENABLE_AUTH === "true";
  }

  private readRequestedOrgId(req: Request): string | null {
    const candidates = [
      req.headers["x-org-id"],
      req.query["org_id"],
      req.query["orgId"],
      req.body?.org_id,
      req.body?.orgId,
    ];

    for (const value of candidates) {
      const normalized = value?.toString().trim();
      if (normalized) return normalized;
    }

    return null;
  }

  private readRequestedBranchIds(req: Request): string[] {
    const keys = [
      "branch_id",
      "branchId",
      "warehouse_id",
      "warehouseId",
      "location_id",
      "locationId",
    ];

    const values = new Set<string>();

    for (const key of keys) {
      const candidates = [req.query[key], req.body?.[key], req.headers[key]];
      for (const value of candidates) {
        const normalized = value?.toString().trim();
        if (normalized) values.add(normalized);
      }
    }

    return Array.from(values);
  }

  private readSelectedTenantId(req: Request): string | null {
    const value = req.headers["x-tenant-id"]?.toString().trim();
    return value && value.length > 0 ? value : null;
  }

  private readSelectedTenantType(req: Request): "ORG" | "BRANCH" | null {
    const value = req.headers["x-tenant-type"]?.toString().trim().toUpperCase();
    if (value === "ORG" || value === "BRANCH") {
      return value;
    }
    return null;
  }

  private readRequestedEntityId(req: Request): string | null {
    const value = req.headers["x-entity-id"]?.toString().trim();
    return value && value.length > 0 ? value : null;
  }

  private async assertRoleAndScope(req: Request) {
    const context = req.tenantContext;
    if (!context) return;

    const requestedOrgId = this.readRequestedOrgId(req);
    const requestedBranchIds = this.readRequestedBranchIds(req);
    const requestedEntityId = this.readRequestedEntityId(req);
    const selectedTenantId = this.readSelectedTenantId(req);
    const selectedTenantType = this.readSelectedTenantType(req);

    // If x-entity-id is provided, validate and use it
    if (requestedEntityId) {
      try {
        const { data, error } = await this.supabaseService
          .getClient()
          .from("organisation_branch_master")
          .select("*")
          .eq("id", requestedEntityId)
          .maybeSingle();

        if (data) {
          context.entityId = data.id;
          context.orgId = data.type === 'ORG' ? data.ref_id : data.parent_id; // Approximation, better to use data correctly
          // If it's a branch, we should find the org it belongs to for orgId
          if (data.type === 'BRANCH') {
            const { data: parent } = await this.supabaseService
              .getClient()
              .from("organisation_branch_master")
              .select("ref_id")
              .eq("id", data.parent_id)
              .maybeSingle();
            context.orgId = parent?.ref_id ?? context.orgId;
            context.branchId = data.ref_id;
          } else {
            context.orgId = data.ref_id;
            context.branchId = null;
          }
        }
      } catch (err) {
        // Fallback or handle error
      }
    }

    if (
      context.role !== "admin" &&
      requestedOrgId &&
      requestedOrgId !== context.orgId
    ) {
      throw new ForbiddenException("Cross-organization access is not allowed");
    }

    if (
      context.role !== "admin" &&
      context.accessibleBranchIds.length > 0 &&
      requestedBranchIds.length > 0 &&
      requestedBranchIds.some(
        (branchId) => !context.accessibleBranchIds.includes(branchId),
      )
    ) {
      throw new ForbiddenException(
        "You do not have access to the requested branch or warehouse",
      );
    }

    if (context.role !== "admin" && selectedTenantId && selectedTenantType) {
      if (selectedTenantType === "ORG" && selectedTenantId !== context.orgId) {
        throw new ForbiddenException(
          "You do not have access to the selected organization",
        );
      }

      if (
        selectedTenantType === "BRANCH" &&
        context.accessibleBranchIds.length > 0 &&
        !context.accessibleBranchIds.includes(selectedTenantId)
      ) {
        throw new ForbiddenException(
          "You do not have access to the selected branch",
        );
      }

      if (selectedTenantType === "BRANCH") {
        context.branchId = selectedTenantId;
      } else {
        context.branchId = null;
      }
    }

    // Resolve entityId based on the current context scope
    if (!context.entityId) {
      try {
        if (context.branchId) {
          const { data } = await this.supabaseService
            .getClient()
            .from("organisation_branch_master")
            .select("id")
            .eq("ref_id", context.branchId)
            .eq("type", "BRANCH")
            .maybeSingle();
          if (data?.id) context.entityId = data.id;
        }

        if (!context.entityId && context.orgId) {
          const { data } = await this.supabaseService
            .getClient()
            .from("organisation_branch_master")
            .select("id")
            .eq("ref_id", context.orgId)
            .eq("type", "ORG")
            .maybeSingle();
          if (data?.id) context.entityId = data.id;
        }
      } catch (err) {
        // Ignore — entityId stays null, service layer will throw a clear error
      }
    }
  }

  private resolveActionFromMethod(method: string): string {
    switch (method.toUpperCase()) {
      case "POST":
        return "create";
      case "PUT":
      case "PATCH":
        return "edit";
      case "DELETE":
        return "delete";
      case "GET":
      default:
        return "view";
    }
  }

  private hasModuleActionPermission(
    permissions: Record<string, unknown> | null | undefined,
    moduleKey: string,
    action: string,
  ): boolean {
    if (!permissions || Object.keys(permissions).length === 0) {
      return false;
    }

    if (permissions["full_access"] === true) {
      return true;
    }

    const rawValue = this.resolvePermissionValue(permissions, moduleKey);
    if (!Array.isArray(rawValue)) {
      return false;
    }

    const values = new Set(rawValue.map((entry) => String(entry)));
    if (values.has("full")) {
      return true;
    }
    return values.has(action);
  }

  private resolvePermissionValue(
    permissions: Record<string, unknown>,
    moduleKey: string,
  ): unknown {
    const direct = permissions[moduleKey];
    if (direct != null) return direct;

    const aliases = TenantMiddleware.moduleAliases[moduleKey] ?? [];
    for (const alias of aliases) {
      const value = permissions[alias];
      if (value != null) return value;
    }
    return null;
  }

  private assertRoutePermission(req: Request) {
    const context = req.tenantContext;
    if (!context || context.role === "admin") {
      return;
    }

    const fullPath = (req.originalUrl || req.path).split("?")[0];
    const matchedRule = TenantMiddleware.apiPermissionRules.find(
      (rule) => fullPath === rule.prefix || fullPath.startsWith(`${rule.prefix}/`),
    );

    const isApiRequest = fullPath.startsWith("/api/v1/");
    const isReadOnlyLookupApi =
      req.method.toUpperCase() === "GET" &&
      (fullPath.startsWith("/api/v1/lookups") ||
        fullPath.startsWith("/api/v1/products/lookups"));
    const isAlwaysAllowedApi =
      isReadOnlyLookupApi ||
      fullPath.includes("/health") ||
      fullPath.includes("/ping") ||
      fullPath.endsWith("/auth/login") ||
      fullPath.endsWith("/auth/refresh") ||
      fullPath.endsWith("/auth/forgot-password") ||
      fullPath.endsWith("/auth/profile") ||
      fullPath.endsWith("/auth/change-password") ||
      fullPath.endsWith("/auth/logout");

    if (!matchedRule) {
      if (isApiRequest && !isAlwaysAllowedApi) {
        throw new ForbiddenException(
          "No RBAC rule defined for this API route. Access denied by default.",
        );
      }
      return;
    }

    if (
      TenantMiddleware.adminOnlyModules.has(matchedRule.moduleKey) &&
      context.role !== "admin"
    ) {
      throw new ForbiddenException(
        `Module '${matchedRule.moduleKey}' is restricted to admin users`,
      );
    }

    const action = this.resolveActionFromMethod(req.method);
    const hasPermission = this.hasModuleActionPermission(
      context.permissions,
      matchedRule.moduleKey,
      action,
    );

    if (!hasPermission) {
      throw new ForbiddenException(
        `Role '${context.role}' does not have ${action} permission for module '${matchedRule.moduleKey}'`,
      );
    }
  }

  async use(req: Request, res: Response, next: NextFunction) {
    if (!this.isAuthEnabled()) {
      req.tenantContext = {
        userId: "00000000-0000-0000-0000-000000000000",
        email: "zabnixprivatelimited@gmail.com",
        orgId: "00000000-0000-0000-0000-000000000002",
        branchId: null,
        entityId: "66d79887-be98-40ab-ac40-9e0a008f9d8a",
        role: "admin",
        accessibleBranchIds: [],
        defaultBusinessBranchId: null,
        defaultWarehouseBranchId: null,
        permissions: null,
        user: null,
      };
      return next();
    }

    // Skip tenant check for health/ping endpoints
    const path = (req.originalUrl || req.path).split("?")[0];
    if (
      path.includes("/health") ||
      path.includes("/ping") ||
      path.endsWith("/auth/login") ||
      path.endsWith("/auth/refresh") ||
      path.endsWith("/auth/forgot-password")
    ) {
      return next();
    }

    // Extract Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      throw new UnauthorizedException("Missing authorization header");
    }

    try {
      const token = authHeader.split(" ")[1];
      const payload = await this.authService.validateToken(token);

      // Attach tenant context to request
      req.tenantContext = {
        userId: payload.sub,
        email: payload.email,
        orgId: payload.orgId,
        branchId: payload.branchId,
        entityId: null, // Will be resolved in assertRoleAndScope
        role: payload.role,
        accessibleBranchIds: payload.accessibleBranchIds,
        defaultBusinessBranchId: payload.defaultBusinessBranchId,
        defaultWarehouseBranchId: payload.defaultWarehouseBranchId,
        permissions: payload.permissions,
        user: payload.user,
      };

      await this.assertRoleAndScope(req);
      this.assertRoutePermission(req);

      next();
    } catch (error) {
      if (error instanceof ForbiddenException) {
        throw error;
      }
      console.error("[TenantMiddleware] Auth error:", error instanceof Error ? error.message : error);
      throw new UnauthorizedException("Invalid or expired token");
    }
  }
}
