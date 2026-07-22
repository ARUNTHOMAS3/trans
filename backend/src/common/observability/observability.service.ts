import { Injectable } from "@nestjs/common";
import { randomUUID } from "crypto";

export interface TelemetryRecord {
  timestamp: string;
  name: string;
  category: string;
  correlationId?: string;
  durationMs?: number;
  metrics?: Record<string, unknown>;
}

@Injectable()
export class ObservabilityService {
  private readonly enabled = process.env.ENABLE_PERFORMANCE_MONITORING === "true";
  private readonly sampleRate = Math.max(
    0,
    Math.min(1, Number(process.env.PERFORMANCE_MONITORING_SAMPLE_RATE ?? "1")),
  );
  private readonly mode = process.env.PERFORMANCE_MONITORING_MODE ?? "production";
  private readonly maxRecords = 5000;
  private readonly records: TelemetryRecord[] = [];

  get isEnabled(): boolean {
    return this.enabled;
  }

  newCorrelationId(): string {
    return randomUUID();
  }

  record(
    name: string,
    category: string,
    options: {
      correlationId?: string;
      durationMs?: number;
      metrics?: Record<string, unknown>;
    } = {},
  ): void {
    if (!this.enabled || Math.random() > this.sampleRate) return;
    const record: TelemetryRecord = {
      timestamp: new Date().toISOString(),
      name,
      category,
      ...(options.correlationId
        ? { correlationId: options.correlationId }
        : {}),
      ...(options.durationMs == null ? {} : { durationMs: options.durationMs }),
      ...(options.metrics ? { metrics: options.metrics } : {}),
    };
    if (this.records.length >= this.maxRecords) this.records.shift();
    this.records.push(record);
    if (this.mode === "console" || process.env.NODE_ENV !== "production") {
      console.info(`[telemetry] ${JSON.stringify(record)}`);
    }
  }

  recordHttp(input: {
    correlationId: string;
    method: string;
    path: string;
    statusCode: number;
    durationMs: number;
    requestBytes: number;
    responseBytes: number;
    controller: string;
    handler: string;
  }): void {
    this.record("http_request", "http", {
      correlationId: input.correlationId,
      durationMs: input.durationMs,
      metrics: {
        method: input.method,
        path: input.path,
        status_code: input.statusCode,
        request_bytes: input.requestBytes,
        response_bytes: input.responseBytes,
        controller: input.controller,
        handler: input.handler,
      },
    });
  }

  recordDatabase(input: {
    correlationId?: string;
    queryFingerprint: string;
    durationMs: number;
    rows: number;
    error?: boolean;
  }): void {
    this.record("database_query", "database", {
      correlationId: input.correlationId,
      durationMs: input.durationMs,
      metrics: {
        query_fingerprint: input.queryFingerprint,
        rows: input.rows,
        error: input.error ?? false,
      },
    });
  }

  snapshot(): TelemetryRecord[] {
    return this.records.slice();
  }

  exportJson(): string {
    return JSON.stringify({
      generated_at: new Date().toISOString(),
      records: this.snapshot(),
    });
  }

  exportCsv(): string {
    const rows = [
      ["timestamp", "category", "name", "duration_ms", "correlation_id", "metrics"],
      ...this.records.map((record) => [
        record.timestamp,
        record.category,
        record.name,
        record.durationMs?.toString() ?? "",
        record.correlationId ?? "",
        JSON.stringify(record.metrics ?? {}),
      ]),
    ];
    return rows
      .map((row) => row.map((value) => `"${value.replace(/"/g, '""')}"`).join(","))
      .join("\n");
  }
}
