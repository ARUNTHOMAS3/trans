import { ReportsService } from "./reports.service";

type QueryResult = {
  data: Array<Record<string, unknown>>;
  count: number;
  error: unknown;
};

const createAuditQueryBuilder = (result: QueryResult) => {
  const calls = {
    order: jest.fn(),
    range: jest.fn(),
    eq: jest.fn(),
    in: jest.fn(),
    gte: jest.fn(),
    lte: jest.fn(),
    not: jest.fn(),
    is: jest.fn(),
    or: jest.fn(),
  };

  const builder: any = {
    select: jest.fn(() => builder),
    order: jest.fn((...args: unknown[]) => {
      calls.order(...args);
      return builder;
    }),
    range: jest.fn((...args: unknown[]) => {
      calls.range(...args);
      return builder;
    }),
    eq: jest.fn((...args: unknown[]) => {
      calls.eq(...args);
      return builder;
    }),
    in: jest.fn((...args: unknown[]) => {
      calls.in(...args);
      return builder;
    }),
    gte: jest.fn((...args: unknown[]) => {
      calls.gte(...args);
      return builder;
    }),
    lte: jest.fn((...args: unknown[]) => {
      calls.lte(...args);
      return builder;
    }),
    not: jest.fn((...args: unknown[]) => {
      calls.not(...args);
      return builder;
    }),
    is: jest.fn((...args: unknown[]) => {
      calls.is(...args);
      return builder;
    }),
    or: jest.fn((...args: unknown[]) => {
      calls.or(...args);
      return builder;
    }),
    then: (
      resolve: (value: QueryResult) => unknown,
      reject?: (reason: unknown) => unknown,
    ) => Promise.resolve(result).then(resolve, reject),
  };

  return { builder, calls };
};

describe("ReportsService.getAuditLogs", () => {
  it("applies filters and returns summary values from the visible page", async () => {
    const { builder, calls } = createAuditQueryBuilder({
      data: [
        { id: "1", action: "UPDATE", archived_at: null },
        { id: "2", action: "DELETE", archived_at: "2026-03-01T00:00:00.000Z" },
        { id: "3", action: "TRUNCATE", archived_at: null },
      ],
      count: 23,
      error: null,
    });

    const service = new ReportsService({
      getClient: () => ({
        from: (table: string) => {
          expect(table).toBe("audit_logs_all");
          return builder;
        },
      }),
    } as any);

    const result = await service.getAuditLogs(
      { orgId: "org-1", entityId: "branch-1" } as any,
      {
        page: 0,
        pageSize: 500,
        search: "manual journals",
        tables: ["accounts_manual_journals"],
        actions: ["UPDATE", "DELETE"],
        requestId: "req-123",
        source: "api",
        fromDate: "2026-03-01",
        toDate: "2026-03-17",
        scope: "archived",
      },
    );

    expect(calls.order).toHaveBeenCalledWith("created_at", {
      ascending: false,
    });
    expect(calls.range).toHaveBeenCalledWith(0, 99);
    expect(calls.eq).toHaveBeenCalledWith("org_id", "org-1");
    expect(calls.eq).toHaveBeenCalledWith("request_id", "req-123");
    expect(calls.eq).toHaveBeenCalledWith("source", "api");
    expect(calls.in).toHaveBeenCalledWith("table_name", [
      "accounts_manual_journals",
    ]);
    expect(calls.in).toHaveBeenCalledWith("action", ["UPDATE", "DELETE"]);
    expect(calls.gte).toHaveBeenCalledWith(
      "created_at",
      "2026-03-01T00:00:00.000Z",
    );
    expect(calls.lte).toHaveBeenCalledWith(
      "created_at",
      "2026-03-17T00:00:00.000Z",
    );
    expect(calls.not).toHaveBeenCalledWith("archived_at", "is", null);
    expect(calls.or).toHaveBeenCalledWith(
      [
        "table_name.ilike.%manual journals%",
        "record_pk.ilike.%manual journals%",
        "actor_name.ilike.%manual journals%",
        "module_name.ilike.%manual journals%",
        "request_id.ilike.%manual journals%",
        "source.ilike.%manual journals%",
        "action.ilike.%manual journals%",
      ].join(","),
    );

    expect(result.total).toBe(23);
    expect(result.page).toBe(1);
    expect(result.pageSize).toBe(100);
    expect(result.summary).toEqual({
      insertCount: 0,
      updateCount: 1,
      deleteCount: 1,
      truncateCount: 1,
      archivedCount: 1,
      visibleItems: 3,
    });
  });

  it("uses recent scope and default pagination when no custom filters are given", async () => {
    const { builder, calls } = createAuditQueryBuilder({
      data: [{ id: "1", action: "INSERT", archived_at: null }],
      count: 1,
      error: null,
    });

    const service = new ReportsService({
      getClient: () => ({
        from: () => builder,
      }),
    } as any);

    const result = await service.getAuditLogs({} as any, {
      scope: "recent",
    });

    expect(calls.range).toHaveBeenCalledWith(0, 24);
    expect(calls.is).toHaveBeenCalledWith("archived_at", null);
    expect(result.summary.insertCount).toBe(1);
    expect(result.summary.visibleItems).toBe(1);
  });
});

describe.skip("ReportsService.getDashboardSummary", () => {
  it("does not apply org_id filters when orgId is missing", async () => {
    const eqCalls: Array<[string, unknown]> = [];

    const createQuery = (result: { data: any; error: unknown }) => {
      const query: any = {
        select: jest.fn(() => query),
        eq: jest.fn((column: string, value: unknown) => {
          eqCalls.push([column, value]);
          return query;
        }),
        gte: jest.fn(() => query),
        filter: jest.fn(() => Promise.resolve(result)),
      };
      return query;
    };

    const service = new ReportsService({
      getClient: () => ({
        from: (table: string) => {
          if (table === "accounts") {
            const accResult = {
              data: [{ id: "acc-1", account_type: "cash", user_account_name: "Cash" }],
              error: null,
            };
            const accQuery: any = {
              select: jest.fn(() => accQuery),
              eq: jest.fn(() => Promise.resolve(accResult)),
            };
            return accQuery;
          }

          if (table === "account_transactions") {
            return createQuery({ data: [], error: null });
          }

          if (table === "customers") {
            return {
              select: () => ({
                eq: () => ({
                  single: async () => ({
                    data: { display_name: "Demo Customer" },
                    error: null,
                  }),
                }),
              }),
            };
          }

          throw new Error(`Unexpected table: ${table}`);
        },
      }),
    } as any);

    await service.getDashboardSummary({ entityId: undefined, orgId: undefined } as any);

    expect(eqCalls).not.toContainEqual(["org_id", undefined]);
    expect(eqCalls).toContainEqual(["contact_type", "customer"]);
  });
});
