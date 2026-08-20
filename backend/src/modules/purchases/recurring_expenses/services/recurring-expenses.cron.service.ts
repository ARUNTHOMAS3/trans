import { Injectable, Logger, OnApplicationBootstrap } from "@nestjs/common";
import { Cron, CronExpression } from "@nestjs/schedule";
import { RecurringExpensesService } from "./recurring-expenses.service";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../../supabase/supabase.service";
import { client } from "../../../../db/db";

@Injectable()
export class RecurringExpensesCronService implements OnApplicationBootstrap {
  private readonly logger = new Logger(RecurringExpensesCronService.name);

  constructor(
    private readonly recurringExpensesService: RecurringExpensesService,
    private readonly supabaseService: SupabaseService,
  ) {}

  async onApplicationBootstrap() {
    this.logger.log("Application startup: executing recurring expenses backfill catch-up...");
    await this.processRecurringExpenses();
  }

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async handleCron() {
    this.logger.debug("Running daily recurring expenses check...");
    await this.processRecurringExpenses();
  }

  async processRecurringExpenses() {
    try {
      await client.unsafe(
        `UPDATE recurring_expenses SET status = 'STOPPED' WHERE status = ANY($1)`,
        [["PAUSED", "COMPLETED", "CANCELLED"]],
      );

      const activeProfiles = await client.unsafe(
        `SELECT * FROM recurring_expenses WHERE status = 'ACTIVE' AND is_delete = false`,
      );

      const now = new Date();
      const todayStr = new Date(now.getTime() - now.getTimezoneOffset() * 60 * 1000)
        .toISOString()
        .split("T")[0];

      let processedCount = 0;

      for (const profile of activeProfiles ?? []) {
        try {
          const resolvedUserId = (profile.created_by || profile.createdById || "").toString().trim();
          if (!resolvedUserId) {
            this.logger.warn(
              `Skipping recurring expense [${profile.profile_name}] due to missing created_by user context.`,
            );
            continue;
          }

          let orgId = "";
          let branchId: string | null = null;

          const entities = await client.unsafe(
            `SELECT ref_id, type, parent_id FROM organisation_branch_master WHERE id = $1 LIMIT 1`,
            [profile.entity_id],
          );
          const entity = entities[0];

          if (entity) {
            if (entity.type === "ORG") {
              orgId = entity.ref_id;
            } else if (entity.type === "BRANCH") {
              branchId = entity.ref_id;
              if (entity.parent_id) {
                const parents = await client.unsafe(
                  `SELECT ref_id FROM organisation_branch_master WHERE id = $1 AND type = 'ORG' LIMIT 1`,
                  [entity.parent_id],
                );
                if (parents[0]?.ref_id) {
                  orgId = parents[0].ref_id;
                }
              }
            }
          }

          if (!orgId) {
            this.logger.warn(
              `Skipping recurring expense [${profile.profile_name}] because organization ID could not be resolved from entity ID ${profile.entity_id}.`,
            );
            continue;
          }

          const tenant: TenantContext = {
            orgId,
            entityId: profile.entity_id,
            branchId,
            userId: resolvedUserId,
            email: "system-scheduler@zerpai.local",
            role: "ho_admin",
            accessibleBranchIds: [],
            defaultBusinessBranchId: branchId,
            defaultWarehouseBranchId: null,
            permissions: { full_access: true },
          };

          const existingRuns = await client.unsafe(
            `SELECT run_date FROM recurring_expense_runs WHERE recurring_expense_id = $1`,
            [profile.id],
          );

          const processedDates = new Set((existingRuns ?? []).map((r: any) => r.run_date));

          let checkDateStr = this.recurringExpensesService.calculateNextRunDate(
            profile.start_date,
            profile.repeat_type,
            profile.repeat_every ?? 1,
          );

          let lastRunDateStr = profile.last_run_date;
          let currentStatus = profile.status;
          let iterations = 0;
          const maxSafetyIterations = 500;

          while (checkDateStr <= todayStr && iterations < maxSafetyIterations) {
            if (profile.end_date && !profile.never_expires && checkDateStr > profile.end_date) {
              currentStatus = "EXPIRED";
              break;
            }

            if (!processedDates.has(checkDateStr)) {
              this.logger.log(
                `Generating backfill/scheduler expense for [${profile.profile_name}] on date: ${checkDateStr}`,
              );

              await this.recurringExpensesService.generateExpenseFromRecurring(
                profile.id,
                tenant,
                checkDateStr,
              );
              processedCount++;
            }

            lastRunDateStr = checkDateStr;

            checkDateStr = this.recurringExpensesService.calculateNextRunDate(
              checkDateStr,
              profile.repeat_type,
              profile.repeat_every ?? 1,
            );

            iterations++;
          }

          let nextRunDateStr: string | null = checkDateStr;
          if (profile.end_date && !profile.never_expires && nextRunDateStr > profile.end_date) {
            nextRunDateStr = null;
            currentStatus = "EXPIRED";
          }

          if (
            profile.next_run_date !== nextRunDateStr ||
            profile.last_run_date !== lastRunDateStr ||
            profile.status !== currentStatus
          ) {
            await client.unsafe(
              `UPDATE recurring_expenses SET last_run_date = $1, next_run_date = $2, status = $3, updated_at = NOW() WHERE id = $4`,
              [lastRunDateStr, nextRunDateStr, currentStatus, profile.id],
            );
          }
        } catch (innerErr) {
          this.logger.error(
            `Failed to execute recurrence run/backfill for profile [${profile.profile_name}]:`,
            innerErr,
          );
        }
      }

      if (processedCount > 0) {
        this.logger.log(`Auto-generated/backfilled ${processedCount} expense entries.`);
      }
    } catch (err) {
      this.logger.error("Error processing recurring expenses job:", err);
    }
  }
}
