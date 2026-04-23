import { Injectable, Logger } from "@nestjs/common";
import { Cron, CronExpression } from "@nestjs/schedule";
import { AccountantService } from "./accountant.service";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Injectable()
export class RecurringJournalsCronService {
  private readonly logger = new Logger(RecurringJournalsCronService.name);

  constructor(private readonly accountantService: AccountantService) {}

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async handleCron() {
    this.logger.debug("Running daily recurring journals check...");
    await this.processRecurringJournals();
  }

  // Exposed for testing/triggering manually if needed
  async processRecurringJournals() {
    try {
      // Use the global fetcher which doesn't filter by a single tenant
      const activeJournals = await this.accountantService.findAllGlobalRecurringJournals();

      let processedCount = 0;
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      for (const journal of activeJournals) {
        // Construct a mock TenantContext from the journal record
        // This is necessary because the service methods now expect a tenant object.
        const tenant: TenantContext = {
          orgId: journal.orgId || journal.org_id,
          entityId: journal.entityId || journal.entity_id,
          branchId: journal.branchId || journal.branch_id,
          userId: journal.createdById || journal.created_by || "00000000-0000-0000-0000-000000000000",
          email: "system@zerpai.com", // Mock email for background tasks
          role: "ho_admin", // Assume HO Admin privileges for automated background tasks
          accessibleBranchIds: [],
          defaultBusinessBranchId: journal.branchId || journal.branch_id || null,
          defaultWarehouseBranchId: null,
          permissions: { full_access: true },
        };

        // Skip if there's an end date and it's already past
        if (journal.endDate && !journal.neverExpires) {
          const end = new Date(journal.endDate);
          end.setHours(0, 0, 0, 0);
          if (today > end) {
            continue; // Journal profile has expired
          }
        }

        let nextRun = journal.lastGeneratedDate
          ? new Date(journal.lastGeneratedDate)
          : new Date(journal.startDate);

        // If it was already generated before, we must calculate the *next* interval
        if (journal.lastGeneratedDate) {
          nextRun = this.calculateNextDate(
            nextRun,
            journal.repeatEvery,
            journal.interval,
          );
        }

        nextRun.setHours(0, 0, 0, 0);

        // Advance through all due recurrences up to today
        let iterations = 0;
        const maxSafetyIterations = 100; // prevent infinite loops if misconfigured interval

        try {
          while (nextRun <= today && iterations < maxSafetyIterations) {
            // Double check end date per-instance
            if (journal.endDate && !journal.neverExpires) {
              const end = new Date(journal.endDate);
              end.setHours(0, 0, 0, 0);
              if (nextRun > end) {
                break;
              }
            }

            this.logger.log(
              `[generate] [${journal.profileName}] Date: ${nextRun.toISOString()}`,
            );

            // Automation Lease: Check if a journal already exists for this date to prevent duplicates
            const generationDate = nextRun.toISOString().split("T")[0];
            const existing =
              await this.accountantService.findManualJournalByRecurring(
                journal.id,
                generationDate,
                tenant,
              );

            if (existing) {
              this.logger.warn(
                `Manual journal already exists for profile [${journal.profileName}] on ${generationDate}. Skipping duplication.`,
              );
            } else {
              await this.accountantService.generateManualJournalFromRecurring(
                journal.id,
                tenant,
                generationDate,
              );
              processedCount++;
            }
            iterations++;

            // Move to the next date
            nextRun = this.calculateNextDate(
              nextRun,
              journal.repeatEvery,
              journal.interval,
            );
            nextRun.setHours(0, 0, 0, 0);
          }
        } catch (innerError) {
          this.logger.error(
            `Failed to execute schedule for recurring profile [${journal.profileName}]. Skipping. ERR:`,
            innerError,
          );
          // If it fails structurally, break out of this loop to prevent infinite retry loops but allow the outer FOR loop to process the next valid journal profile
        }
      }

      if (processedCount > 0) {
        this.logger.log(`Created ${processedCount} new manual journals.`);
      }
    } catch (error) {
      this.logger.error("Error processing recurring journals:", error);
    }
  }

  private calculateNextDate(base: Date, unit: string, interval: number): Date {
    const next = new Date(base);
    const n = Math.max(1, interval);
    const u = unit.toLowerCase();

    if (u.includes("week")) {
      next.setDate(next.getDate() + 7 * n);
    } else if (u.includes("month")) {
      next.setMonth(next.getMonth() + n);
    } else if (u.includes("year")) {
      next.setFullYear(next.getFullYear() + n);
    } else {
      next.setDate(next.getDate() + n);
    }
    return next;
  }
}
