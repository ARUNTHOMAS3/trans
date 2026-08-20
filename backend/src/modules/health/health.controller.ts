import { Controller, Get } from "@nestjs/common";
import { SupabaseService } from "../supabase/supabase.service";
import { RedisService } from "../redis/redis.service";
import { db } from "../../db/db";
import { unit } from "../../db/schema";
import { sql } from "drizzle-orm";

@Controller("health")
export class HealthController {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly redisService: RedisService,
  ) {}

  @Get()
  async checkHealth() {
    const status = {
      status: "ok",
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV,
      database: "unknown",
      config: {
        hasSupabaseUrl: !!process.env.SUPABASE_URL,
        hasServiceKey: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
        supabaseUrlPrefix: process.env.SUPABASE_URL?.substring(0, 8) + "...",
        hasRedisUrl: this.redisService.isConfigured,
        hasRedisRestUrl: !!this.redisService.restUrl,
        hasRedisRestToken: !!this.redisService.restToken,
      },
      redis: "unknown",
    };

    try {
      // Verify DB connection using Drizzle
      await db.select({ val: sql`1` }).from(unit).limit(1);
      status.database = "connected";
    } catch (e) {
      status.database = "exception";
      status["exception_message"] = e.message;
    }

    const redis = await this.redisService.ping();
    status.redis = redis.configured
      ? redis.reachable
        ? "connected"
        : "error"
      : "not_configured";

    if (redis.error) {
      status["redis_error"] = redis.error;
    }

    return status;
  }
}
