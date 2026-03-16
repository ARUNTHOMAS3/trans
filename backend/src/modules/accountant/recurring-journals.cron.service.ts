import { Injectable, Logger } from "@nestjs/common";
import { Cron, CronExpression } from "@nestjs/schedule";
import { AccountantService } from "./accountant.service";

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
      const journals = await this.accountantService.findRecurringJournals();
      // Only process active journals
      const activeJournals = journals.filter((j) => j.status === "active");

      let processedCount = 0;
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      for (const journal of activeJournals) {
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
              );

            if (existing) {
              this.logger.warn(
                `Manual journal already exists for profile [${journal.profileName}] on ${generationDate}. Skipping duplication.`,
              );
            } else {
              await this.accountantService.generateManualJournalFromRecurring(
                journal.id,
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
