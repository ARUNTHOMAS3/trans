import { ReportsController } from "./reports.controller";

describe("ReportsController", () => {
  it("normalizes audit log query params before forwarding to the service", async () => {
    const getAuditLogs = jest.fn().mockResolvedValue({ items: [] });
    const controller = new ReportsController({
      getAuditLogs,
    } as any);

    await controller.getAuditLogs(
      "2",
      "50",
      "manual journals",
      "manual_journals, account_transactions ,",
      "update, delete",
      "req-123",
      "api",
      "org-1",
      "outlet-1",
      "2026-03-01",
      "2026-03-17",
      "recent",
    );

    expect(getAuditLogs).toHaveBeenCalledWith({
      page: 2,
      pageSize: 50,
      search: "manual journals",
      tables: ["manual_journals", "account_transactions"],
      actions: ["UPDATE", "DELETE"],
      requestId: "req-123",
      source: "api",
      orgId: "org-1",
      outletId: "outlet-1",
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

    await controller.getAuditLogs(
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
      undefined,
      undefined,
    );

    expect(getAuditLogs).toHaveBeenCalledWith({
      page: undefined,
      pageSize: undefined,
      search: undefined,
      tables: undefined,
      actions: undefined,
      requestId: undefined,
      source: undefined,
      orgId: undefined,
      outletId: undefined,
      fromDate: undefined,
      toDate: undefined,
      scope: undefined,
    });
  });
});
