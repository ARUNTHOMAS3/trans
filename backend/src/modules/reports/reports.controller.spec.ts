import { ReportsController } from "./reports.controller";

describe("ReportsController", () => {
  it("normalizes audit log query params before forwarding to the service", async () => {
    const getAuditLogs = jest.fn().mockResolvedValue({ items: [] });
    const controller = new ReportsController({
      getAuditLogs,
    } as any);

    const mockTenant = {} as any;
    await controller.getAuditLogs(
      mockTenant,
      "2",
      "50",
      "manual journals",
      "accounts_manual_journals, account_transactions ,",
      "update, delete",
      "req-123",
      "api",
      "2026-03-01",
      "2026-03-17",
      "recent",
    );

    expect(getAuditLogs).toHaveBeenCalledWith(mockTenant, {
      page: 2,
      pageSize: 50,
      search: "manual journals",
      tables: ["accounts_manual_journals", "account_transactions"],
      actions: ["UPDATE", "DELETE"],
      requestId: "req-123",
      source: "api",
      fromDate: "2026-03-01",
      toDate: "2026-03-17",
      scope: "recent",
    });
  });

  it("drops invalid numeric values when parsing audit log query params", async () => {
    const getAuditLogs = jest.fn().mockResolvedValue({ items: [] });
    const controller = new ReportsController({
      getAuditLogs,
    } as any);

    const mockTenant2 = {} as any;
    await controller.getAuditLogs(
      mockTenant2,
      "x",
      "nan",
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
    );

    expect(getAuditLogs).toHaveBeenCalledWith(mockTenant2, {
      page: undefined,
      pageSize: undefined,
      search: undefined,
      tables: undefined,
      actions: undefined,
      requestId: undefined,
      source: undefined,
      fromDate: undefined,
      toDate: undefined,
      scope: undefined,
    });
  });
});
