import { Injectable, Logger, OnModuleDestroy } from "@nestjs/common";
import IORedis, { Redis } from "ioredis";

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis | null = null;

  get isConfigured(): boolean {
    return !!process.env.UPSTASH_REDIS_URL;
  }

  get restUrl(): string | undefined {
    return process.env.UPSTASH_REDIS_REST_URL;
  }

  get restToken(): string | undefined {
    return process.env.UPSTASH_REDIS_REST_TOKEN;
  }

  getClient(): Redis | null {
    if (!this.isConfigured) {
      return null;
    }

    if (!this.client) {
      this.client = this.createClient("redis");
      this.logger.log("Redis client initialized from env configuration");
    }

    return this.client;
  }

  async ping(): Promise<{
    configured: boolean;
    reachable: boolean;
    response?: string;
    error?: string;
  }> {
    if (!this.isConfigured) {
      return { configured: false, reachable: false };
    }

    try {
      const client = this.getClient();
      if (!client) {
        return { configured: false, reachable: false };
      }

      const response = await client.ping();
      return { configured: true, reachable: true, response };
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      this.logger.warn(`Redis ping failed: ${message}`);
      return {
        configured: true,
        reachable: false,
        error: message,
      };
    }
  }

  createBullMqConnection(name = "bullmq"): Redis {
    return this.createClient(name);
  }

  async onModuleDestroy(): Promise<void> {
    if (this.client) {
      await this.client.quit().catch(() => this.client?.disconnect());
      this.client = null;
    }
  }

  private createClient(connectionName: string): Redis {
    const redisUrl = process.env.UPSTASH_REDIS_URL;

    if (!redisUrl) {
      throw new Error("UPSTASH_REDIS_URL is not configured");
    }

    return new IORedis(redisUrl, {
      connectionName: `zerpai-${connectionName}`,
      lazyConnect: true,
      maxRetriesPerRequest: null,
      enableReadyCheck: false,
    });
  }
}
