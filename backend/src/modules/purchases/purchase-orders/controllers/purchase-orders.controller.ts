import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
} from "@nestjs/common";
import { PurchaseOrdersService } from "../services/purchase-orders.service";
import { CreatePurchaseOrderDto } from "../dto/create-purchase-order.dto";
import { UpdatePurchaseOrderDto } from "../dto/update-purchase-order.dto";

@Controller("purchase-orders")
export class PurchaseOrdersController {
  constructor(private readonly purchaseOrdersService: PurchaseOrdersService) {}

  @Get()
  async findAll(
    @Query("page") page: number = 1,
    @Query("limit") limit: number = 100,
    @Query("search") search?: string,
    @Query("status") status?: string,
    @Query("vendorId") vendorId?: string,
  ) {
    return this.purchaseOrdersService.findAll(
      page,
      limit,
      search,
      status,
      vendorId,
    );
  }

  @Get(":id")
  async findOne(@Param("id") id: string) {
    return this.purchaseOrdersService.findOne(id);
  }

  @Post()
  async create(@Body() createPurchaseOrderDto: CreatePurchaseOrderDto) {
    return this.purchaseOrdersService.create(createPurchaseOrderDto);
  }

  @Put(":id")
  async update(
    @Param("id") id: string,
    @Body() updatePurchaseOrderDto: UpdatePurchaseOrderDto,
  ) {
    return this.purchaseOrdersService.update(id, updatePurchaseOrderDto);
  }

  @Delete(":id")
  async remove(@Param("id") id: string) {
    return this.purchaseOrdersService.remove(id);
  }
}
