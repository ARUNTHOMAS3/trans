import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  Put,
  HttpCode,
  HttpStatus,
  UsePipes,
  ValidationPipe,
  Query,
} from "@nestjs/common";
import { ProductsService } from "./products.service";
import { CreateProductDto } from "./dto/create-product.dto";
import { UpdateProductDto } from "./dto/update-product.dto";
import { Tenant } from "../../common/decorators/tenant.decorator";
import { TenantContext } from "../../common/middleware/tenant.middleware";

@Controller("products")
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get("lookups/units")
  getUnits(@Tenant() tenant: TenantContext) {
    return this.productsService.getUnits(tenant);
  }

  @Get("lookups/uqc")
  getUQCs() {
    return this.productsService.getUQCs();
  }

  @Post("lookups/units/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncUnits(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncUnits(items, tenant);
  }

  @Post("lookups/units/check-usage")
  @HttpCode(HttpStatus.OK)
  checkUnitUsage(@Body() body: { unitIds: string[] }) {
    return this.productsService.checkUnitUsage(body.unitIds);
  }

  @Post("lookups/:type/check-usage")
  @HttpCode(HttpStatus.OK)
  checkLookupUsage(@Param("type") type: string, @Body() body: { id: string }) {
    return this.productsService.checkLookupUsage(type, body.id);
  }

  @Get("lookups/content-units")
  getContentUnits(@Tenant() tenant: TenantContext) {
    return this.productsService.getContentUnits(tenant);
  }

  @Post("lookups/content-units/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncContentUnits(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncContentUnits(items, tenant);
  }

  @Get("lookups/categories")
  getCategories(@Tenant() tenant: TenantContext) {
    return this.productsService.getCategories(tenant);
  }

  @Post("lookups/categories/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  async syncCategories(@Body() items: any[], @Tenant() tenant: TenantContext) {
    try {
      console.log(
        "📥 Received categories sync request with",
        items.length,
        "items",
      );
      const result = await this.productsService.syncCategories(items, tenant);
      console.log("✅ Categories sync completed successfully");
      return result;
    } catch (error) {
      console.error("💥 FATAL ERROR in syncCategories controller:");
      console.error("Error message:", error.message);
      console.error("Error stack:", error.stack);
      console.error("Full error:", JSON.stringify(error, null, 2));
      throw error;
    }
  }

  @Get("lookups/tax-rates")
  getTaxRates(@Tenant() tenant: TenantContext) {
    return this.productsService.getTaxRates(tenant);
  }

  @Post("lookups/tax-rates/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncTaxRates(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncTaxRates(items, tenant);
  }

  @Get("lookups/tax-groups")
  getTaxGroups(@Tenant() tenant: TenantContext) {
    return this.productsService.getTaxGroups(tenant);
  }

  @Post("lookups/tax-groups/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncTaxGroups(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncTaxGroups(items, tenant);
  }

  @Get("lookups/manufacturers")
  getManufacturers(@Tenant() tenant: TenantContext) {
    return this.productsService.getManufacturers(tenant);
  }

  @Post("lookups/manufacturers/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  async syncManufacturers(
    @Body() items: any[],
    @Tenant() tenant: TenantContext,
  ) {
    try {
      console.log(
        "📥 Received manufacturers sync request with",
        items.length,
        "items",
      );
      const result = await this.productsService.syncManufacturers(items, tenant);
      console.log("✅ Manufacturers sync completed successfully");
      return result;
    } catch (error) {
      console.error("💥 FATAL ERROR in syncManufacturers controller:");
      console.error("Error message:", error.message);
      console.error("Error stack:", error.stack);
      console.error("Full error:", JSON.stringify(error, null, 2));
      throw error;
    }
  }

  @Get("lookups/brands")
  getBrands(@Tenant() tenant: TenantContext) {
    return this.productsService.getBrands(tenant);
  }

  @Get("lookups/bootstrap")
  getLookupBootstrap(@Tenant() tenant: TenantContext) {
    return this.productsService.getLookupBootstrap(tenant);
  }

  @Get("lookups/manufacturers/search")
  searchManufacturers(@Query("q") query: string, @Tenant() tenant: TenantContext) {
    return this.productsService.searchManufacturers(query, tenant);
  }

  @Get("lookups/brands/search")
  searchBrands(@Query("q") query: string, @Tenant() tenant: TenantContext) {
    return this.productsService.searchBrands(query, tenant);
  }

  @Post("lookups/brands/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncBrands(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncBrands(items, tenant);
  }

  @Get("lookups/vendors")
  getVendors(@Tenant() tenant: TenantContext) {
    return this.productsService.getVendors(tenant);
  }

  @Get("lookups/reps")
  getReps(@Tenant() tenant: TenantContext) {
    return this.productsService.getReps(tenant);
  }

  @Get("lookups/reps/search")
  searchReps(@Query("q") query: string, @Tenant() tenant: TenantContext) {
    return this.productsService.searchReps(query, tenant);
  }

  @Post("lookups/reps")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  createRep(@Body() repData: any, @Tenant() tenant: TenantContext) {
    return this.productsService.createRep(repData, tenant);
  }

  @Post("lookups/vendors/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncVendors(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncVendors(items, tenant);
  }

  @Get("lookups/storage-locations")
  getStorageLocations(@Tenant() tenant: TenantContext) {
    return this.productsService.getStorageLocations(tenant);
  }

  @Get("lookups/warehouses")
  getWarehouses(@Tenant() tenant: TenantContext) {
    return this.productsService.getWarehouses(tenant);
  }

  @Post("lookups/storage-locations/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncStorageLocations(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncStorageLocations(items, tenant);
  }

  @Get("lookups/racks")
  getRacks(@Tenant() tenant: TenantContext) {
    return this.productsService.getRacks(tenant);
  }

  @Post("lookups/racks/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncRacks(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncRacks(items, tenant);
  }

  @Get("lookups/reorder-terms")
  getReorderTerms(@Tenant() tenant: TenantContext) {
    return this.productsService.getReorderTerms(tenant);
  }

  @Post("lookups/reorder-terms")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  async createReorderTerm(
    @Body() termData: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.productsService.createReorderTerm(termData, tenant);
  }

  @Put("lookups/reorder-terms/:id")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  async updateReorderTerm(
    @Param("id") id: string,
    @Body() termData: any,
    @Tenant() tenant: TenantContext,
  ) {
    return this.productsService.updateReorderTerm(id, termData, tenant);
  }

  @Delete("lookups/reorder-terms/:id")
  async deleteReorderTerm(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.productsService.deleteReorderTerm(id, tenant);
  }

  @Post("lookups/reorder-terms/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  async syncReorderTerms(
    @Body() items: any[],
    @Tenant() tenant: TenantContext,
  ) {
    try {
      console.log(
        "📥 Received reorder terms sync request with",
        items.length,
        "items",
      );
      const result = await this.productsService.syncReorderTerms(items, tenant);
      console.log("✅ Reorder terms sync completed successfully");
      return result;
    } catch (error) {
      console.error("💥 FATAL ERROR in syncReorderTerms controller:");
      console.error("Error message:", error.message);
      throw error;
    }
  }

  @Get("lookups/accountant")
  getAccounts(@Tenant() tenant: TenantContext) {
    return this.productsService.getAccounts(tenant);
  }

  @Post("lookups/accountant/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncAccounts(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncAccounts(items, tenant);
  }

  @Get("lookups/contents")
  getContents(@Tenant() tenant: TenantContext) {
    return this.productsService.getContents(tenant);
  }

  @Post("lookups/contents/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncContents(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncContents(items, tenant);
  }

  @Get("lookups/strengths")
  getStrengths(@Tenant() tenant: TenantContext) {
    return this.productsService.getStrengths(tenant);
  }

  @Post("lookups/strengths/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncStrengths(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncStrengths(items, tenant);
  }

  @Get("lookups/buying-rules")
  getBuyingRules(@Tenant() tenant: TenantContext) {
    return this.productsService.getBuyingRules(tenant);
  }

  @Post("lookups/buying-rules/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncBuyingRules(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncBuyingRules(items, tenant);
  }

  @Get("lookups/drug-schedules")
  getDrugSchedules(@Tenant() tenant: TenantContext) {
    return this.productsService.getDrugSchedules(tenant);
  }

  @Get("lookups/product-types")
  getProductTypes(@Tenant() tenant: TenantContext) {
    return this.productsService.getProductTypes(tenant);
  }

  @Get("lookups/product-pack-sizes")
  getProductPackSizes(@Tenant() tenant: TenantContext) {
    return this.productsService.getProductPackSizes(tenant);
  }

  @Get("lookups/product-pack-sizes/search")
  searchProductPackSizes(
    @Query("q") query: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.productsService.searchProductPackSizes(query, tenant);
  }

  @Post("lookups/product-pack-sizes")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  createProductPackSize(@Body() packSizeData: any, @Tenant() tenant: TenantContext) {
    return this.productsService.createProductPackSize(packSizeData, tenant);
  }

  @Get("lookups/product-types/search")
  searchProductTypes(
    @Query("q") query: string,
    @Tenant() tenant: TenantContext,
  ) {
    return this.productsService.searchProductTypes(query, tenant);
  }

  @Post("lookups/product-types")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  createProductType(@Body() typeData: any, @Tenant() tenant: TenantContext) {
    return this.productsService.createProductType(typeData, tenant);
  }

  @Post("lookups/product-types/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncProductTypes(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncProductTypes(items, tenant);
  }

  @Post("lookups/drug-schedules/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncDrugSchedules(@Body() items: any[], @Tenant() tenant: TenantContext) {
    return this.productsService.syncDrugSchedules(items, tenant);
  }

  @Get("search")
  async searchProducts(
    @Query("q") q?: string,
    @Query("limit") limit?: string,
    @Query("branch_id") branch_id?: string,
  ) {
    const parsedLimit = limit ? parseInt(limit, 10) : 30;
    return this.productsService.searchProducts(q, parsedLimit, branch_id);
  }

  @Get()
  async findAll(
    @Query("limit") limit?: string,
    @Query("offset") offset?: string,
    @Query("cursor") cursor?: string,
  ) {
    const parsedLimit = limit ? parseInt(limit, 10) : undefined;
    const parsedOffset = offset ? parseInt(offset, 10) : undefined;

    if (offset !== undefined && cursor === undefined) {
      return this.productsService.findAll(parsedLimit, parsedOffset);
    }

    return this.productsService.findAllCursor(parsedLimit ?? 50, cursor);
  }

  @Get("count")
  async countProducts() {
    return this.productsService.countProducts();
  }

  @Get("composite")
  async getComposite(@Tenant() tenant: TenantContext) {
    return this.productsService.getCompositeItems(tenant);
  }

  @Get(":id/quick-stats")
  async getQuickStats(@Param("id") id: string) {
    return this.productsService.getQuickStats(id);
  }

  @Get(":id/warehouse-stocks")
  async getWarehouseStocks(@Param("id") id: string) {
    return this.productsService.getProductWarehouseStocks(id);
  }

  @Get(":id/history")
  async getProductHistory(@Param("id") id: string) {
    return this.productsService.getProductHistory(id);
  }

  @Put(":id/warehouse-stocks")
  async updateWarehouseStocks(
    @Param("id") id: string,
    @Body() body: { rows?: any[] },
  ) {
    return this.productsService.updateProductWarehouseStocks(id, body);
  }

  @Post(":id/warehouse-stocks/physical-adjustments")
  async adjustPhysicalWarehouseStock(
    @Param("id") id: string,
    @Body()
    body: {
      warehouse_id?: string;
      counted_stock?: number;
      reason?: string;
      notes?: string;
    },
  ) {
    return this.productsService.adjustProductWarehousePhysicalStock(id, body);
  }

  @Get(":id/batches")
  async getBatches(@Param("id") id: string) {
    return this.productsService.getBatches(id);
  }

  @Get(":id")
  async findOne(@Param("id") id: string, @Tenant() tenant: TenantContext) {
    return this.productsService.findOne(id, tenant);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @Body() createProductDto: CreateProductDto,
    @Tenant() tenant: TenantContext,
  ) {
    console.log(
      "📥 Received product data:",
      JSON.stringify(createProductDto, null, 2),
    );
    return this.productsService.create(createProductDto, tenant.userId, tenant);
  }

  @Post("composite")
  @HttpCode(HttpStatus.CREATED)
  async createComposite(@Body() payload: any, @Tenant() tenant: TenantContext) {
    console.log("📥 Received composite product data");
    return this.productsService.createComposite(payload, tenant.userId, tenant);
  }

  @Put("bulk")
  async bulkUpdate(
    @Body() body: { ids: string[]; changes: UpdateProductDto },
    @Tenant() tenant: TenantContext,
  ) {
    const userId = tenant.userId || null;
    const ids = Array.isArray(body?.ids) ? body.ids : [];
    const changes = (body?.changes ?? {}) as UpdateProductDto;
    return this.productsService.bulkUpdate(ids, changes, userId);
  }

  @Put(":id")
  async update(
    @Param("id") id: string,
    @Body() updateProductDto: UpdateProductDto,
    @Tenant() tenant: TenantContext,
  ) {
    return this.productsService.update(
      id,
      updateProductDto,
      tenant.userId,
      tenant,
    );
  }

  @Delete(":id")
  async remove(@Param("id") id: string, @Tenant() tenant: TenantContext) {
    return this.productsService.remove(id, tenant);
  }
}

@Controller("branch_inventory")
export class BranchInventoryController {
  constructor(private readonly productsService: ProductsService) {}

  @Post("bulk")
  @HttpCode(HttpStatus.OK)
  async getBulkStock(
    @Tenant() tenant: TenantContext,
    @Body() body: { product_ids: string[] },
  ) {
    if (!Array.isArray(body?.product_ids)) {
      return { stocks: [] };
    }

    return this.productsService.getBulkStock(body.product_ids, tenant);
  }
}
