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

  async sendEmail(payload: ResendEmailPayload) {
    const from = payload.from ?? process.env.RESEND_FROM_EMAIL?.trim();

    if (!from) {
      throw new Error(
        "Missing RESEND_FROM_EMAIL. Set a verified sender email in backend/.env.",
      );
    }

    return this.getClient().emails.send({
      from,
      to: payload.to,
      subject: payload.subject,
      html: payload.html,
    });
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
