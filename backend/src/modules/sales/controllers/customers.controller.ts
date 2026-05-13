import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
  HttpStatus,
  BadRequestException,
} from "@nestjs/common";
import { CustomersService } from "../services/customers.service";
import { CreateCustomerDto } from "../dto/create-customer.dto";
import { UpdateCustomerDto } from "../dto/update-customer.dto";
import { Tenant } from "../../../common/decorators/tenant.decorator";
import { TenantContext } from "../../../common/middleware/tenant.middleware";

@Controller("sales/customers")
export class CustomersController {
  constructor(private readonly customersService: CustomersService) {}

  @Get()
  async findAll(
    @Tenant() tenant: TenantContext,
    @Query("page") page?: string,
    @Query("limit") limit?: string,
    @Query("search") search?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 100;

    const result = await this.customersService.findAll(
      tenant,
      pageNum,
      limitNum,
      search,
    );
    return {
      data: result.data,
      meta: {
        page: pageNum,
        limit: limitNum,
        total: result.total,
        totalPages: Math.ceil(result.total / limitNum),
      },
    };
  }

  @Get(":id")
  async findOne(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    const customer = await this.customersService.findOne(id, tenant);
    if (!customer) {
      return {
        statusCode: HttpStatus.NOT_FOUND,
        message: "Customer not found",
      };
    }
    return { data: customer };
  }

  @Get(":id/detail-context")
  async getDetailContext(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    const context = await this.customersService.getDetailContext(id, tenant);
    if (!context) {
      return {
        statusCode: HttpStatus.NOT_FOUND,
        message: "Customer not found",
      };
    }
    return { data: context };
  }

  @Post()
  async create(@Tenant() tenant: TenantContext, @Body() createCustomerDto: CreateCustomerDto) {
    try {
      const customer = await this.customersService.create(createCustomerDto, tenant);
      return {
        data: customer,
        message: "Customer created successfully",
      };
    } catch (error) {
      console.error("--- Create Customer Error ---");
      console.error(error);
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: error.message,
      };
    }
  }

  @Put(":id")
  async update(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
    @Body() updateCustomerDto: UpdateCustomerDto,
  ) {
    try {
      const customer = await this.customersService.update(
        id,
        tenant,
        updateCustomerDto,
      );
      if (!customer) {
        return {
          statusCode: HttpStatus.NOT_FOUND,
          message: "Customer not found",
        };
      }
      return {
        data: customer,
        message: "Customer updated successfully",
      };
    } catch (error) {
      return {
        statusCode: HttpStatus.BAD_REQUEST,
        message: error.message,
      };
    }
  }

  @Delete(":id")
  async remove(
    @Tenant() tenant: TenantContext,
    @Param("id") id: string,
  ) {
    const result = await this.customersService.remove(id, tenant);
    if (!result) {
      return {
        statusCode: HttpStatus.NOT_FOUND,
        message: "Customer not found",
      };
    }
    return {
      message: "Customer deleted successfully",
    };
  }

  @Get("statistics/overview")
  async getStatistics(@Tenant() tenant: TenantContext) {
    const stats = await this.customersService.getStatistics(tenant);
    return { data: stats };
  }
}
