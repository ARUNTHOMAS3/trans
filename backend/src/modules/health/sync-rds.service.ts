import { Injectable, Logger } from "@nestjs/common";
import postgres from "postgres";

@Injectable()
export class SyncRdsService {
  private readonly logger = new Logger(SyncRdsService.name);

  async syncSupabaseToRds(): Promise<{ status: string; syncedTables: number; details: any }> {
    const supabaseUrl =
      "postgresql://postgres.jhaqdcstdxynrbsomadt:688iOB8UhgYAsTgF@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=no-verify";
    const rdsUrl =
      process.env.DRIZZLE_DATABASE_URL ||
      process.env.DATABASE_URL ||
      "postgresql://postgres:zabnix2026@zerpai-db.cziuqia28x6a.ap-south-2.rds.amazonaws.com:5432/zerpai";

    this.logger.log("Starting Supabase -> AWS RDS Schema & Data Sync...");

    const src = postgres(supabaseUrl, { ssl: { rejectUnauthorized: false }, max: 5, connect_timeout: 10 });
    const dst = postgres(rdsUrl, { ssl: "prefer", max: 5, connect_timeout: 10 });

    try {
      // 1. Enable uuid-ossp extension on RDS
      await dst.unsafe(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`);
      await dst.unsafe(`CREATE EXTENSION IF NOT EXISTS "pgcrypto";`);

      // 2. Fetch all enums from Supabase and create on RDS
      const enums = await src.unsafe<any[]>(`
        SELECT t.typname as enum_name, array_agg(e.enumlabel ORDER BY e.enumsortorder) as enum_values
        FROM pg_type t
        JOIN pg_enum e ON t.oid = e.enumtypid
        JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public'
        GROUP BY t.typname;
      `);

      for (const en of enums) {
        try {
          const vals = (en.enum_values as string[]).map((v) => `'${v.replace(/'/g, "''")}'`).join(", ");
          await dst.unsafe(`
            DO $$ BEGIN
              CREATE TYPE "${en.enum_name}" AS ENUM (${vals});
            EXCEPTION
              WHEN duplicate_object THEN null;
            END $$;
          `);
        } catch (e: any) {
          this.logger.warn(`Enum creation warning for ${en.enum_name}: ${e.message}`);
        }
      }

      // 3. Fetch all table names
      const tables = await src.unsafe<any[]>(`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
        ORDER BY table_name;
      `);

      const syncedTableNames: string[] = [];

      // Drop any conflicting view before creating base tables
      try {
        await dst.unsafe(`DROP VIEW IF EXISTS "organization" CASCADE;`);
      } catch {}

      // Disable foreign key constraints temporarily for fast, safe loading
      await dst.unsafe(`SET session_replication_role = 'replica';`);

      for (const t of tables) {
        const tableName = t.table_name as string;

        // Fetch column definitions
        const cols = await src.unsafe<any[]>(`
          SELECT column_name, udt_name, is_nullable, column_default, data_type, character_maximum_length
          FROM information_schema.columns 
          WHERE table_schema = 'public' AND table_name = $1
          ORDER BY ordinal_position;
        `, [tableName]);

        if (cols.length === 0) continue;

        const colDefs = cols.map((c) => {
          let typeDef: string;
          if (c.data_type === "USER-DEFINED") {
            typeDef = `"${c.udt_name}"`;
          } else if (c.data_type === "ARRAY") {
            typeDef = `${c.udt_name.replace(/^_/, "")}[]`;
          } else if (c.data_type === "character varying") {
            typeDef = c.character_maximum_length ? `varchar(${c.character_maximum_length})` : "text";
          } else if (c.data_type === "timestamp with time zone") {
            typeDef = "timestamptz";
          } else if (c.data_type === "timestamp without time zone") {
            typeDef = "timestamp";
          } else if (c.data_type === "boolean") {
            typeDef = "boolean";
          } else if (c.data_type === "integer") {
            typeDef = "integer";
          } else if (c.data_type === "bigint") {
            typeDef = "bigint";
          } else if (c.data_type === "smallint") {
            typeDef = "smallint";
          } else {
            typeDef = c.data_type;
          }

          let def = `"${c.column_name}" ${typeDef}`;
          return def;
        });

        // Create table on RDS if not exists
        try {
          await dst.unsafe(`CREATE TABLE IF NOT EXISTS "${tableName}" (${colDefs.join(", ")});`);
          
          // Ensure any missing columns on existing tables are added
          for (const col of cols) {
            try {
              let typeDef = col.data_type === "USER-DEFINED" ? `"${col.udt_name}"` : col.data_type;
              await dst.unsafe(`ALTER TABLE "${tableName}" ADD COLUMN IF NOT EXISTS "${col.column_name}" ${typeDef};`);
            } catch {}
          }
        } catch (e: any) {
          this.logger.warn(`Table creation error for ${tableName}: ${e.message}`);
          continue;
        }

        // Fetch data from Supabase and copy to RDS
        try {
          const rows = await src.unsafe<any[]>(`SELECT * FROM "${tableName}";`);
          if (rows.length > 0) {
            // Truncate before insert
            await dst.unsafe(`TRUNCATE TABLE "${tableName}" CASCADE;`);
            
            // Insert in chunks of 500
            const chunkSize = 500;
            for (let i = 0; i < rows.length; i += chunkSize) {
              const chunk = rows.slice(i, i + chunkSize);
              await dst`INSERT INTO ${dst(tableName)} ${dst(chunk)}`;
            }
          }
          syncedTableNames.push(`${tableName} (${rows.length} rows)`);
        } catch (e: any) {
          this.logger.warn(`Data copy error for ${tableName}: ${e.message}`);
        }
      }

      // Re-enable foreign key constraints
      await dst.unsafe(`SET session_replication_role = 'origin';`);

      this.logger.log(`Sync completed successfully! Total tables synced: ${syncedTableNames.length}`);

      return {
        status: "success",
        syncedTables: syncedTableNames.length,
        details: syncedTableNames,
      };
    } catch (err: any) {
      this.logger.error(`Sync failed: ${err.message}`, err.stack);
      throw err;
    } finally {
      await src.end();
      await dst.end();
    }
  }
}
