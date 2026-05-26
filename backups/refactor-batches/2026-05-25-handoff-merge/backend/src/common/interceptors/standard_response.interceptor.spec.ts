import { of, lastValueFrom } from "rxjs";
import { ExecutionContext } from "@nestjs/common";
import { StandardResponseInterceptor } from "./standard_response.interceptor";

describe("StandardResponseInterceptor", () => {
  const createContext = (url: string, query: Record<string, unknown> = {}) =>
    ({
      switchToHttp: () => ({
        getRequest: () => ({
          originalUrl: url,
          query,
        }),
      }),
    }) as ExecutionContext;

  it("passes health responses through unchanged", async () => {
    const interceptor = new StandardResponseInterceptor();
    const result = await lastValueFrom(
      interceptor.intercept(createContext("/api/v1/health"), {
        handle: () => of({ status: "ok" }),
      } as any),
    );

    expect(result).toEqual({ status: "ok" });
  });

  it("wraps plain payloads in standard shape", async () => {
    const interceptor = new StandardResponseInterceptor();
    const result = await lastValueFrom(
      interceptor.intercept(createContext("/api/v1/items", { page: "2" }), {
        handle: () => of([{ id: 1 }, { id: 2 }]),
      } as any),
    );

    expect(result.data).toEqual([{ id: 1 }, { id: 2 }]);
    expect(result.meta.page).toBe(2);
    expect(result.meta.total).toBe(2);
    expect(result.meta.timestamp).toBeDefined();
  });
});
