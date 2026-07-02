import { TenantContext } from "./middleware/tenant.middleware";

type AccountRow = Record<string, any>;

type VisibleAccountOptions = {
  select?: string;
  includeDeleted?: boolean;
  includeInactive?: boolean;
  accountType?: string;
  accountGroup?: string;
  search?: string;
  limit?: number;
};

function normalize(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

export function hasSystemAccountName(row: AccountRow | null | undefined) {
  return normalize(row?.system_account_name ?? row?.systemAccountName).length > 0;
}

export function isTenantOwnedAccount(
  row: AccountRow | null | undefined,
  tenant: Pick<TenantContext, "entityId">,
) {
  const rowEntityId = normalize(row?.entity_id ?? row?.entityId);
  const tenantEntityId = normalize(tenant.entityId);
  return tenantEntityId.length > 0 && rowEntityId === tenantEntityId;
}

export function canTenantReadAccount(
  row: AccountRow | null | undefined,
  tenant: Pick<TenantContext, "entityId">,
) {
  return isTenantOwnedAccount(row, tenant) || hasSystemAccountName(row);
}

export function getVisibleAccountName(
  row: AccountRow | null | undefined,
  tenant: Pick<TenantContext, "entityId">,
) {
  const systemName = normalize(row?.system_account_name ?? row?.systemAccountName);
  const userName = normalize(row?.user_account_name ?? row?.userAccountName);
  const accountName = normalize(row?.account_name ?? row?.accountName ?? row?.name);

  if (isTenantOwnedAccount(row, tenant)) {
    return userName || systemName || accountName;
  }

  return systemName || accountName || userName;
}

export function sanitizeVisibleAccountRow<T extends AccountRow>(
  row: T,
  tenant: Pick<TenantContext, "entityId">,
) {
  const isOwned = isTenantOwnedAccount(row, tenant);
  const visibleName = getVisibleAccountName(row, tenant);

  return {
    ...row,
    user_account_name: isOwned
      ? row.user_account_name ?? row.userAccountName ?? null
      : null,
    userAccountName: isOwned
      ? row.userAccountName ?? row.user_account_name ?? null
      : null,
    account_name: visibleName || null,
    accountName: visibleName || null,
    name: visibleName || null,
    label: visibleName || null,
    display_name: visibleName || null,
    visible_name: visibleName || null,
    is_shared_system_account: !isOwned && hasSystemAccountName(row),
  };
}

function matchesSearch(
  row: AccountRow,
  tenant: Pick<TenantContext, "entityId">,
  search: string,
) {
  const normalizedSearch = normalize(search).toLowerCase();
  if (!normalizedSearch) return true;

  const haystack = [
    getVisibleAccountName(row, tenant),
    normalize(row.system_account_name ?? row.systemAccountName),
    isTenantOwnedAccount(row, tenant)
      ? normalize(row.user_account_name ?? row.userAccountName)
      : "",
    normalize(row.account_code ?? row.accountCode),
  ]
    .filter((value) => value.length > 0)
    .join(" ")
    .toLowerCase();

  return haystack.includes(normalizedSearch);
}

export async function listVisibleAccounts(
  client: any,
  tenant: Pick<TenantContext, "entityId">,
  options: VisibleAccountOptions = {},
) {
  const tenantEntityId = normalize(tenant.entityId);
  let query = client.from("accounts").select(options.select ?? "*");

  if (!options.includeDeleted) {
    query = query.eq("is_deleted", false);
  }
  if (!options.includeInactive) {
    query = query.eq("is_active", true);
  }
  if (options.accountType) {
    query = query.eq("account_type", options.accountType);
  }
  if (options.accountGroup) {
    query = query.eq("account_group", options.accountGroup);
  }

  if (tenantEntityId) {
    query = query.or(
      `entity_id.eq.${tenantEntityId},system_account_name.not.is.null`,
    );
  } else {
    query = query.not("system_account_name", "is", null);
  }

  const { data, error } = await query;
  if (error) throw error;

  const visibleRows = (data ?? [])
    .filter((row: AccountRow) => canTenantReadAccount(row, tenant))
    .filter((row: AccountRow) =>
      options.search ? matchesSearch(row, tenant, options.search) : true,
    )
    .map((row: AccountRow) => sanitizeVisibleAccountRow(row, tenant))
    .sort((left: AccountRow, right: AccountRow) =>
      getVisibleAccountName(left, tenant).localeCompare(
        getVisibleAccountName(right, tenant),
        undefined,
        { numeric: true, sensitivity: "base" },
      ),
    );

  if (options.limit && options.limit > 0) {
    return visibleRows.slice(0, options.limit);
  }

  return visibleRows;
}

export async function getVisibleAccountById(
  client: any,
  id: string,
  tenant: Pick<TenantContext, "entityId">,
  options: Pick<VisibleAccountOptions, "includeDeleted" | "includeInactive"> = {},
) {
  const { data, error } = await client
    .from("accounts")
    .select("*")
    .eq("id", id)
    .maybeSingle();

  if (error) throw error;
  if (!data) return null;
  if (!canTenantReadAccount(data, tenant)) return null;
  if (!options.includeDeleted && data.is_deleted === true) return null;
  if (!options.includeInactive && data.is_active === false) return null;

  return sanitizeVisibleAccountRow(data, tenant);
}
