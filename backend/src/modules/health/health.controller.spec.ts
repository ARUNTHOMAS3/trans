import { HealthController } from "./health.controller";

const mockRedis = {
  isConfigured: false,
  restUrl: null,
  restToken: null,
  ping: async () => ({ configured: false, reachable: false }),
} as any;

describe("HealthController", () => {
  it("reports connected when supabase query succeeds", async () => {
    const controller = new HealthController({
      getClient: () => ({
        from: () => ({
          select: async () => ({ error: null }),
        }),
      }),
    } as any, mockRedis);

    const result = (await controller.checkHealth()) as any;

    expect(result.status).toBe("ok");
    expect(result.database).toBe("connected");
  });

  it("reports error when supabase returns an error object", async () => {
    const controller = new HealthController({
      getClient: () => ({
        from: () => ({
          select: async () => ({
            error: { message: "db failure", code: "DB001" },
          }),
        }),
      }),
    } as any, mockRedis);

    const result = (await controller.checkHealth()) as any;

    expect(result.database).toBe("error");
    expect(result.error_details).toBe("db failure");
    expect(result.error_code).toBe("DB001");
  });

  it("reports exception when client throws", async () => {
    const controller = new HealthController({
      getClient: () => ({
        from: () => ({
          select: async () => {
            throw new Error("boom");
          },
        }),
      }),
    } as any, mockRedis);

    const result = (await controller.checkHealth()) as any;

    expect(result.database).toBe("exception");
    expect(result.exception_message).toBe("boom");
  });
});
