import { Injectable, Logger } from "@nestjs/common";
import { Resend } from "resend";

export interface ResendEmailPayload {
  to: string | string[];
  subject: string;
  html: string;
  from?: string;
}

@Injectable()
export class ResendService {
  private readonly logger = new Logger(ResendService.name);
  private client: Resend | null = null;

  private get apiKey(): string {
    const apiKey = process.env.RESEND_API_KEY?.trim();

    if (!apiKey || apiKey === "re_xxxxxxxxx") {
      throw new Error(
        "Missing RESEND_API_KEY. Replace `re_xxxxxxxxx` with your real API key in backend/.env.",
      );
    }

    return apiKey;
  }

  private getClient(): Resend {
    if (this.client == null) {
      this.client = new Resend(this.apiKey);
    }

    return this.client;
  }

  private maskEmail(value: string): string {
    const trimmed = value.trim();
    const [localPart, domainPart] = trimmed.split("@");
    if (!localPart || !domainPart) return trimmed;
    if (localPart.length <= 2) {
      return `${localPart[0] ?? "*"}***@${domainPart}`;
    }
    return `${localPart.slice(0, 2)}***@${domainPart}`;
  }

  private maskRecipients(to: string | string[]): string {
    if (Array.isArray(to)) {
      return to.map((value) => this.maskEmail(value)).join(", ");
    }
    return this.maskEmail(to);
  }

  async sendEmail(payload: ResendEmailPayload) {
    const from = payload.from ?? process.env.RESEND_FROM_EMAIL?.trim();

    if (!from) {
      throw new Error(
        "Missing RESEND_FROM_EMAIL. Set a verified sender email in backend/.env.",
      );
    }

    this.logger.log(
      `Resend send start → to=${this.maskRecipients(payload.to)} subject="${payload.subject}" from=${this.maskEmail(from)}`,
    );

    try {
      const result = await this.getClient().emails.send({
        from,
        to: payload.to,
        subject: payload.subject,
        html: payload.html,
      });

      const responseError = (result as any)?.error;
      if (responseError) {
        const message =
          responseError.message?.toString().trim() ||
          JSON.stringify(responseError);
        this.logger.error(
          `Resend send failed → to=${this.maskRecipients(payload.to)} subject="${payload.subject}" error=${message}`,
        );
        throw new Error(`Resend send failed: ${message}`);
      }

      const emailId =
        (result as any)?.data?.id?.toString?.() ||
        (result as any)?.id?.toString?.() ||
        "unknown";
      this.logger.log(
        `Resend send success → to=${this.maskRecipients(payload.to)} subject="${payload.subject}" email_id=${emailId}`,
      );
      return result;
    } catch (error) {
      const message =
        error instanceof Error ? error.message : JSON.stringify(error);
      this.logger.error(
        `Resend send exception → to=${this.maskRecipients(payload.to)} subject="${payload.subject}" error=${message}`,
      );
      throw error;
    }
  }

  async sendHelloWorldEmail(
    to = process.env.RESEND_TEST_TO_EMAIL?.trim() ||
      "zabnixprivatelimited@gmail.com",
  ) {
    this.logger.log(`Sending Resend hello-world email to ${to}`);

    return this.sendEmail({
      to,
      subject: "Hello World",
      html: "<p>Congrats on sending your <strong>first email</strong>!</p>",
    });
  }
}
