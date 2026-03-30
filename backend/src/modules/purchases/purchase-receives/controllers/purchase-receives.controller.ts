import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
} from "@nestjs/common";
import { PurchaseReceivesService } from "../services/purchase-receives.service";
import { CreatePurchaseReceiveDto } from "../dto/create-purchase-receive.dto";
import { UpdatePurchaseReceiveDto } from "../dto/update-purchase-receive.dto";

@Controller("purchase-receives")
export class PurchaseReceivesController {
  constructor(private readonly purchaseReceivesService: PurchaseReceivesService) {}

  @Post()
  create(@Body() createDto: CreatePurchaseReceiveDto) {
    return this.purchaseReceivesService.create(createDto);
  }

  @Get()
  findAll(
    @Query("page") page?: number,
    @Query("limit") limit?: number,
    @Query("search") search?: string,
    @Query("status") status?: string,
  ) {
    return this.purchaseReceivesService.findAll(
      page ? +page : 1,
      limit ? +limit : 100,
      search,
      status,
    );
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.purchaseReceivesService.findOne(id);
  }

  @Patch(":id")
  update(
    @Param("id") id: string,
    @Body() updateDto: UpdatePurchaseReceiveDto,
  ) {
    return this.purchaseReceivesService.update(id, updateDto);
  }

  @Delete(":id")
  remove(@Param("id") id: string) {
    return this.purchaseReceivesService.remove(id);
  }
}
