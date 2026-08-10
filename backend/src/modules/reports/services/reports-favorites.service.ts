import { BadRequestException, Injectable } from "@nestjs/common";
import { TenantContext } from "../../../common/middleware/tenant.middleware";
import { ReportFavoriteDto } from "../dto/report-favorite.dto";
import { ReportsFavoritesRepository } from "../repositories/reports-favorites.repository";

@Injectable()
export class ReportsFavoritesService {
  constructor(
    private readonly reportsFavoritesRepository: ReportsFavoritesRepository,
  ) {}

  private normalizeReport(value: string | undefined | null): string {
    const report = value?.trim() ?? "";
    if (!report) {
      throw new BadRequestException("Report identifier is required");
    }
    return report;
  }

  async getFavorites(tenant: TenantContext) {
    const favorites = await this.reportsFavoritesRepository.findAll(tenant);
    return {
      data: favorites,
      meta: {
        total: favorites.length,
      },
    };
  }

  async saveFavorite(tenant: TenantContext, dto: ReportFavoriteDto) {
    const result = await this.reportsFavoritesRepository.save(
      tenant,
      this.normalizeReport(dto.report),
    );

    return {
      data: result.record,
      meta: {
        created: result.created,
      },
    };
  }

  async removeFavorite(tenant: TenantContext, report: string) {
    const normalizedReport = this.normalizeReport(report);
    const removed = await this.reportsFavoritesRepository.remove(
      tenant,
      normalizedReport,
    );

    return {
      data: {
        report: normalizedReport,
        removed,
      },
      meta: {
        removed,
      },
    };
  }
}
