import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from "@nestjs/common";
import { Observable } from "rxjs";
import { map } from "rxjs/operators";

interface StandardMeta {
  page?: number;
  limit?: number;
  total?: number;
  timestamp: string;
}

interface StandardResponse<T> {
  data: T;
  meta: StandardMeta;
}

@Injectable()
export class StandardResponseInterceptor<T> implements NestInterceptor<
  T,
  StandardResponse<T>
> {
  intercept(
    context: ExecutionContext,
    next: CallHandler<T>,
  ): Observable<StandardResponse<T>> {
    const request = context.switchToHttp().getRequest();
    const url: string = request?.originalUrl ?? request?.url ?? "";

    if (url.includes("/health")) {
      return next.handle() as Observable<StandardResponse<T>>;
    }

    return next.handle().pipe(
      map((payload: any) => {
        if (payload && typeof payload === "object" && "data" in payload) {
          const meta =
            payload.meta && typeof payload.meta === "object"
              ? payload.meta
              : this.buildMeta(payload.data, request);
          return {
            data: payload.data,
            meta: {
              ...meta,
              timestamp: meta.timestamp ?? new Date().toISOString(),
            },
          } as StandardResponse<T>;
        }

        const meta = this.buildMeta(payload, request);
        return { data: payload, meta } as StandardResponse<T>;
      }),
    );
  }

  private buildMeta(payload: any, request: any): StandardMeta {
    const meta: StandardMeta = {
      timestamp: new Date().toISOString(),
    };

    const pageRaw = request?.query?.page;
    const limitRaw = request?.query?.limit;
    const page = pageRaw != null ? Number(pageRaw) : undefined;
    const limit = limitRaw != null ? Number(limitRaw) : undefined;

    if (Number.isFinite(page)) meta.page = page;
    if (Number.isFinite(limit)) meta.limit = limit;

    if (Array.isArray(payload)) {
      meta.total = payload.length;
    } else if (payload && typeof payload === "object") {
      if (typeof payload.total === "number") meta.total = payload.total;
      if (typeof payload.count === "number") meta.total = payload.count;
    }

    return meta;
  }
}
