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
  Req,
  Query,
} from "@nestjs/common";
import { ProductsService } from "./products.service";
import { CreateProductDto } from "./dto/create-product.dto";
import { UpdateProductDto } from "./dto/update-product.dto";

@Controller("products")
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  private getScopeFromRequest(
    req: any,
    query?: { orgId?: string; outletId?: string },
  ) {
    return {
      orgId:
        query?.orgId ?? req?.tenantContext?.orgId ?? req?.user?.orgId ?? null,
      outletId:
        query?.outletId ??
        req?.tenantContext?.outletId ??
        req?.user?.outletId ??
        null,
    };
  }

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
    @Req() req: any,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.productsService.getLookupBootstrap(
      this.getScopeFromRequest(req, { orgId, outletId }),
    );
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
  getWarehouses(
    @Req() req: any,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.productsService.getWarehouses(
      this.getScopeFromRequest(req, { orgId, outletId }),
    );
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
    @Req() req: any,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.productsService.getReorderTerms(
      this.getScopeFromRequest(req, { orgId, outletId }),
    );
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
    @Req() req: any,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.productsService.createReorderTerm(
      termData,
      this.getScopeFromRequest(req, { orgId, outletId }),
    );
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
    @Req() req: any,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.productsService.updateReorderTerm(
      id,
      termData,
      this.getScopeFromRequest(req, { orgId, outletId }),
    );
  }

  @Delete("lookups/reorder-terms/:id")
  async deleteReorderTerm(
    @Param("id") id: string,
    @Req() req: any,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.productsService.deleteReorderTerm(
      id,
      this.getScopeFromRequest(req, { orgId, outletId }),
    );
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
    @Req() req: any,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    try {
      console.log(
        "📥 Received reorder terms sync request with",
        items.length,
        "items",
      );
      const result = await this.productsService.syncReorderTerms(
        items,
        this.getScopeFromRequest(req, { orgId, outletId }),
      );
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
    @Query("outlet_id") outlet_id?: string,
  ) {
    const parsedLimit = limit ? parseInt(limit, 10) : 30;
    return this.productsService.searchProducts(q, parsedLimit, outlet_id);
  }

  @Get()
  async findAll(
    @Query("limit") limit?: string,
    @Query("offset") offset?: string,
    @Query("cursor") cursor?: string,
  ) {
    const parsedLimit = limit ? parseInt(limit, 10) : undefined;
    const parsedOffset = offset ? parseInt(offset, 10) : undefined;

    // If offset-only request (legacy, e.g., from old sync), return plain array for compatibility
    if (offset !== undefined && cursor === undefined) {
      return this.productsService.findAll(parsedLimit, parsedOffset);
    }

    // Always use cursor format for new consumers (cursor may be undefined on first page, that's fine)
    return this.productsService.findAllCursor(parsedLimit ?? 50, cursor);
  }

  @Get("count")
  async countProducts() {
    return this.productsService.countProducts();
  }

  @Get("composite")
  async getComposite(
    @Req() req: any,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.productsService.getCompositeItems(
      this.getScopeFromRequest(req, { orgId, outletId }),
    );
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
    @Req() req: any,
    @Query("orgId") orgId?: string,
    @Query("outletId") outletId?: string,
  ) {
    return this.productsService.findOne(
      id,
      this.getScopeFromRequest(req, { orgId, outletId }),
    );
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() createProductDto: CreateProductDto, @Req() req: any) {
    console.log(
      "📥 Received product data:",
      JSON.stringify(createProductDto, null, 2),
    );
    const userId = req.user?.id || req.tenantContext?.userId || null;
    return this.productsService.create(
      createProductDto,
      userId,
      this.getScopeFromRequest(req),
    );
  }

  @Post("composite")
  @HttpCode(HttpStatus.CREATED)
  async createComposite(@Body() payload: any, @Req() req: any) {
    console.log("📥 Received composite product data");
    const userId = req.user?.id || req.tenantContext?.userId || null;
    return this.productsService.createComposite(
      payload,
      userId,
      this.getScopeFromRequest(req),
    );
  }

  @Put("bulk")
  async bulkUpdate(
    @Body() body: { ids: string[]; changes: UpdateProductDto },
    @Req() req: any,
  ) {
    const userId = req.user?.id || null;
    const ids = Array.isArray(body?.ids) ? body.ids : [];
    const changes = (body?.changes ?? {}) as UpdateProductDto;
    return this.productsService.bulkUpdate(ids, changes, userId);
  }

  @Put(":id")
  async update(
    @Param("id") id: string,
    @Body() updateProductDto: UpdateProductDto,
    @Req() req: any,
  ) {
    const userId = req.user?.id || req.tenantContext?.userId || null;
    return this.productsService.update(
      id,
      updateProductDto,
      userId,
      this.getScopeFromRequest(req),
    );
  }

  @Get("warehouse/:warehouseId")
  async getWarehouseProducts(@Param("warehouseId") warehouseId: string) {
    return this.productsService.getProductsByWarehouse(warehouseId);
  }

  @Delete(":id")
  async remove(@Param("id") id: string) {
    return this.productsService.remove(id);
  }
}

@Controller("outlet_inventory")
export class OutletInventoryController {
  constructor(private readonly productsService: ProductsService) {}

  @Post("bulk")
  @HttpCode(HttpStatus.OK)
  async getBulkStock(
    @Body() body: { outlet_id: string; product_ids: string[] },
  ) {
    if (!body?.outlet_id || !Array.isArray(body?.product_ids)) {
      return { stocks: [] };
    }
    return this.productsService.getBulkStock(body.outlet_id, body.product_ids);
  }
}
