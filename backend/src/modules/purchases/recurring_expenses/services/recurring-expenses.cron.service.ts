import { Injectable, Logger, OnApplicationBootstrap } from "@nestjs/common";
import { Cron, CronExpression } from "@nestjs/schedule";
import { RecurringExpensesService } from "./recurring-expenses.service";
import { TenantContext } from "../../../../common/middleware/tenant.middleware";
import { SupabaseService } from "../../../supabase/supabase.service";

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

  // Exposed for manual trigger/testing
  async processRecurringExpenses() {
    try {
      const client = this.supabaseService.getClient();

      await client
        .from("recurring_expenses")
        .update({ status: "STOPPED" })
        .in("status", ["PAUSED", "COMPLETED", "CANCELLED"]);

      // Fetch all active profiles (not soft-deleted, status is ACTIVE)
      const { data: activeProfiles, error: fetchError } = await client
        .from("recurring_expenses")
        .select("*")
        .eq("status", "ACTIVE")
        .eq("is_delete", false);

      if (fetchError) {
        throw new Error(`Failed to fetch active recurring profiles: ${fetchError.message}`);
      }

      const now = new Date();
      const todayStr = new Date(now.getTime() - now.getTimezoneOffset() * 60 * 1000)
        .toISOString()
        .split("T")[0];

      let processedCount = 0;

      for (const profile of activeProfiles) {
        try {
          const resolvedUserId = (profile.created_by || profile.createdById || "").toString().trim();
          if (!resolvedUserId) {
            this.logger.warn(
              `Skipping recurring expense [${profile.profile_name}] due to missing created_by user context.`,
            );
            continue;
          }

          // Resolve orgId and branchId from entity_id (organisation_branch_master)
          let orgId = "";
          let branchId: string | null = null;

          const { data: entity } = await client
            .from("organisation_branch_master")
            .select("ref_id, type, parent_id")
            .eq("id", profile.entity_id)
            .maybeSingle();

          if (entity) {
            if (entity.type === "ORG") {
              orgId = entity.ref_id;
            } else if (entity.type === "BRANCH") {
              branchId = entity.ref_id;
              if (entity.parent_id) {
                const { data: parent } = await client
                  .from("organisation_branch_master")
                  .select("ref_id")
                  .eq("id", entity.parent_id)
                  .eq("type", "ORG")
                  .maybeSingle();
                if (parent?.ref_id) {
                  orgId = parent.ref_id;
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

          // Construct mock TenantContext
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

          // Fetch all existing runs for duplicate prevention
          const { data: existingRuns } = await client
            .from("recurring_expense_runs")
            .select("run_date")
            .eq("recurring_expense_id", profile.id);

          const processedDates = new Set(existingRuns?.map((r) => r.run_date) ?? []);

          // Loop through all scheduled dates starting from start_date + 1 interval
          let checkDateStr = this.recurringExpensesService.calculateNextRunDate(
            profile.start_date,
            profile.repeat_type,
            profile.repeat_every ?? 1,
          );

          let lastRunDateStr = profile.last_run_date;
          let currentStatus = profile.status;
          let iterations = 0;
          const maxSafetyIterations = 500; // Covers long execution history

          while (checkDateStr <= todayStr && iterations < maxSafetyIterations) {
            // If profile has end date, check if we exceed it
            if (profile.end_date && !profile.never_expires && checkDateStr > profile.end_date) {
              currentStatus = "EXPIRED";
              break;
            }

            if (!processedDates.has(checkDateStr)) {
              this.logger.log(
                `Generating backfill/scheduler expense for [${profile.profile_name}] on date: ${checkDateStr}`,
              );

              // Generate expense (creates run log automatically)
              await this.recurringExpensesService.generateExpenseFromRecurring(
                profile.id,
                tenant,
                checkDateStr,
              );
              processedCount++;
            }

            lastRunDateStr = checkDateStr;

            // Advance check date
            checkDateStr = this.recurringExpensesService.calculateNextRunDate(
              checkDateStr,
              profile.repeat_type,
              profile.repeat_every ?? 1,
            );

            iterations++;
          }

          // Calculate next_run_date
          let nextRunDateStr: string | null = checkDateStr;
          if (profile.end_date && !profile.never_expires && nextRunDateStr > profile.end_date) {
            nextRunDateStr = null;
            currentStatus = "EXPIRED";
          }

          // Save advanced/recalculated dates back to profile
          if (
            profile.next_run_date !== nextRunDateStr ||
            profile.last_run_date !== lastRunDateStr ||
            profile.status !== currentStatus
          ) {
            await client
              .from("recurring_expenses")
              .update({
                last_run_date: lastRunDateStr,
                next_run_date: nextRunDateStr,
                status: currentStatus,
                updated_at: new Date().toISOString(),
              })
              .eq("id", profile.id);
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
