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
  getUnits() {
    return this.productsService.getUnits();
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
  syncUnits(@Body() items: any[]) {
    return this.productsService.syncUnits(items);
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
  getContentUnits() {
    return this.productsService.getContentUnits();
  }

  @Post("lookups/content-units/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncContentUnits(@Body() items: any[]) {
    return this.productsService.syncContentUnits(items);
  }

  @Get("lookups/categories")
  getCategories() {
    return this.productsService.getCategories();
  }

  @Post("lookups/categories/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  async syncCategories(@Body() items: any[]) {
    try {
      console.log(
        "📥 Received categories sync request with",
        items.length,
        "items",
      );
      const result = await this.productsService.syncCategories(items);
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
  getTaxRates() {
    return this.productsService.getTaxRates();
  }

  @Post("lookups/tax-rates/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncTaxRates(@Body() items: any[]) {
    return this.productsService.syncTaxRates(items);
  }

  @Get("lookups/tax-groups")
  getTaxGroups() {
    return this.productsService.getTaxGroups();
  }

  @Post("lookups/tax-groups/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncTaxGroups(@Body() items: any[]) {
    return this.productsService.syncTaxGroups(items);
  }

  @Get("lookups/manufacturers")
  getManufacturers() {
    return this.productsService.getManufacturers();
  }

  @Post("lookups/manufacturers/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  async syncManufacturers(@Body() items: any[]) {
    try {
      console.log(
        "📥 Received manufacturers sync request with",
        items.length,
        "items",
      );
      const result = await this.productsService.syncManufacturers(items);
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
  getBrands() {
    return this.productsService.getBrands();
  }

  @Get("lookups/bootstrap")
  getLookupBootstrap(
    @Tenant() tenant: TenantContext,
  ) {
    return this.productsService.getLookupBootstrap(tenant);
  }

  @Get("lookups/manufacturers/search")
  searchManufacturers(@Query("q") query: string) {
    return this.productsService.searchManufacturers(query);
  }

  @Get("lookups/brands/search")
  searchBrands(@Query("q") query: string) {
    return this.productsService.searchBrands(query);
  }

  @Post("lookups/brands/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncBrands(@Body() items: any[]) {
    return this.productsService.syncBrands(items);
  }

  @Get("lookups/vendors")
  getVendors() {
    return this.productsService.getVendors();
  }

  @Post("lookups/vendors/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncVendors(@Body() items: any[]) {
    return this.productsService.syncVendors(items);
  }

  @Get("lookups/storage-locations")
  getStorageLocations() {
    return this.productsService.getStorageLocations();
  }

  @Get("lookups/warehouses")
  getWarehouses() {
    return this.productsService.getWarehouses();
  }

  @Post("lookups/storage-locations/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncStorageLocations(@Body() items: any[]) {
    return this.productsService.syncStorageLocations(items);
  }

  @Get("lookups/racks")
  getRacks() {
    return this.productsService.getRacks();
  }

  @Post("lookups/racks/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncRacks(@Body() items: any[]) {
    return this.productsService.syncRacks(items);
  }

  @Get("lookups/reorder-terms")
  getReorderTerms(
    @Tenant() tenant: TenantContext,
  ) {
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
  getAccounts() {
    return this.productsService.getAccounts();
  }

  @Post("lookups/accountant/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncAccounts(@Body() items: any[]) {
    return this.productsService.syncAccounts(items);
  }

  @Get("lookups/contents")
  getContents() {
    return this.productsService.getContents();
  }

  @Post("lookups/contents/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncContents(@Body() items: any[]) {
    return this.productsService.syncContents(items);
  }

  @Get("lookups/strengths")
  getStrengths() {
    return this.productsService.getStrengths();
  }

  @Post("lookups/strengths/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncStrengths(@Body() items: any[]) {
    return this.productsService.syncStrengths(items);
  }

  @Get("lookups/buying-rules")
  getBuyingRules() {
    return this.productsService.getBuyingRules();
  }

  @Post("lookups/buying-rules/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncBuyingRules(@Body() items: any[]) {
    return this.productsService.syncBuyingRules(items);
  }

  @Get("lookups/drug-schedules")
  getDrugSchedules() {
    return this.productsService.getDrugSchedules();
  }

  @Post("lookups/drug-schedules/sync")
  @UsePipes(
    new ValidationPipe({
      transform: true,
      whitelist: false,
      forbidNonWhitelisted: false,
    }),
  )
  syncDrugSchedules(@Body() items: any[]) {
    return this.productsService.syncDrugSchedules(items);
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
  async getComposite(
    @Tenant() tenant: TenantContext,
  ) {
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
  async findOne(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
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
    return this.productsService.create(
      createProductDto,
      tenant.userId,
      tenant,
    );
  }

  @Post("composite")
  @HttpCode(HttpStatus.CREATED)
  async createComposite(
    @Body() payload: any,
    @Tenant() tenant: TenantContext,
  ) {
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
  async remove(
    @Param("id") id: string,
    @Tenant() tenant: TenantContext,
  ) {
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
