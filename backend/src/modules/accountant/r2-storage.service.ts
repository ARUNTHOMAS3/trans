import { Injectable, Logger } from "@nestjs/common";
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import * as crypto from "crypto";

@Injectable()
export class R2StorageService {
  private readonly logger = new Logger(R2StorageService.name);
  private readonly s3Client: S3Client;

  private readonly accountId = process.env.CLOUDFLARE_ACCOUNT_ID;
  private readonly accessKeyId = process.env.CLOUDFLARE_ACCESS_KEY_ID;
  private readonly secretAccessKey = process.env.CLOUDFLARE_SECRET_ACCESS_KEY;
  private readonly bucketName = process.env.CLOUDFLARE_BUCKET_NAME;
  private readonly endpoint = process.env.CLOUDFLARE_R2_ENDPOINT;

  constructor() {
    this.s3Client = new S3Client({
      region: "auto",
      endpoint: this.endpoint,
      credentials: {
        accessKeyId: this.accessKeyId,
        secretAccessKey: this.secretAccessKey,
      },
    });
  }

  /**
   * Uploads a file to Cloudflare R2.
   * Returns the "Key" of the file, NOT the public URL.
   */
  async uploadFile(
    fileName: string,
    fileBuffer: Buffer,
    mimeType: string,
    prefix: string = "manual-journals",
  ): Promise<string> {
    const key = `${prefix}/${crypto.randomUUID()}-${fileName}`;

    try {
      this.logger.log(
        `Uploading ${fileName} to R2 bucket ${this.bucketName} with prefix ${prefix}...`,
      );

      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: key,
        Body: fileBuffer,
        ContentType: mimeType,
      });

      await this.s3Client.send(command);
      return key; // We store the Key in the database
    } catch (error) {
      this.logger.error(`R2 Upload Failed for ${fileName}:`, error);
      throw error;
    }
  }

  /**
   * Generates a presigned URL for viewing/downloading a file.
   * Default expiration is 1 hour (3600 seconds).
   */
  async getPresignedUrl(key: string, expiresIn = 3600): Promise<string> {
    try {
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: key,
      });

      return await getSignedUrl(this.s3Client, command, { expiresIn });
    } catch (error) {
      this.logger.error(
        `Failed to generate Presigned URL for key: ${key}`,
        error,
      );
      throw error;
    }
  }

  /**
   * Deletes a file from Cloudflare R2.
   */
  async deleteFile(key: string): Promise<void> {
    try {
      this.logger.log(`Deleting file from R2: ${key}`);
      const command = new DeleteObjectCommand({
        Bucket: this.bucketName,
        Key: key,
      });

      await this.s3Client.send(command);
    } catch (error) {
      this.logger.error(`R2 Deletion Failed for key: ${key}`, error);
      // We don't throw here to avoid failing a cascade delete, but we log it.
    }
  }
}
