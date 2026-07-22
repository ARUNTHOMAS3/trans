import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from "@nestjs/common";
import { Observable } from "rxjs";
import { finalize } from "rxjs/operators";
import { Request, Response } from "express";
import { ObservabilityService } from "./observability.service";

@Injectable()
export class ObservabilityInterceptor implements NestInterceptor {
  constructor(private readonly observability: ObservabilityService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (!this.observability.isEnabled) return next.handle();

    const request = context.switchToHttp().getRequest<Request>();
    const response = context.switchToHttp().getResponse<Response>();
    const startedAt = request.observabilityStartedAt ?? process.hrtime.bigint();
    const correlationId = request.correlationId ?? this.observability.newCorrelationId();
    const requestBytes = Number(request.headers["content-length"] ?? 0) || 0;
    const controller = context.getClass().name;
    const handler = context.getHandler().name;
    let responseBytes = 0;
    const originalWrite = response.write.bind(response);
    const originalEnd = response.end.bind(response);
    response.write = ((chunk: any, ...args: any[]) => {
      responseBytes += byteLength(chunk);
      return originalWrite(chunk, ...args);
    }) as typeof response.write;
    response.end = ((chunk?: any, ...args: any[]) => {
      if (chunk != null) responseBytes += byteLength(chunk);
      return originalEnd(chunk, ...args);
    }) as typeof response.end;

    return next.handle().pipe(
      finalize(() => {
        const durationMs = Number(process.hrtime.bigint() - startedAt) / 1e6;
        responseBytes ||= Number(response.getHeader("content-length") ?? 0) || 0;
        this.observability.recordHttp({
          correlationId,
          method: request.method,
          path: (request.originalUrl || request.url).split("?")[0],
          statusCode: response.statusCode,
          durationMs,
          requestBytes,
          responseBytes,
          controller,
          handler,
        });
      }),
    );
  }
}

function byteLength(value: unknown): number {
  if (value == null) return 0;
  if (Buffer.isBuffer(value)) return value.length;
  if (value instanceof Uint8Array) return value.byteLength;
  return Buffer.byteLength(String(value));
}
