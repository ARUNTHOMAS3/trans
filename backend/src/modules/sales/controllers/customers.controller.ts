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
} from "@nestjs/common";
import { CustomersService } from "../services/customers.service";
import { CreateCustomerDto } from "../dto/create-customer.dto";
import { UpdateCustomerDto } from "../dto/update-customer.dto";

@Controller("sales/customers")
export class CustomersController {
  constructor(private readonly customersService: CustomersService) {}

  @Get()
  async findAll(
    @Query("page") page?: string,
    @Query("limit") limit?: string,
    @Query("search") search?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 100;

    const result = await this.customersService.findAll(
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
  async findOne(@Param("id") id: string) {
    const customer = await this.customersService.findOne(id);
    if (!customer) {
      return {
        statusCode: HttpStatus.NOT_FOUND,
        message: "Customer not found",
      };
    }
    return { data: customer };
  }

  @Post()
  async create(@Body() createCustomerDto: CreateCustomerDto) {
    try {
      console.log("--- Create Customer Request ---");
      console.log(JSON.stringify(createCustomerDto, null, 2));
      const customer = await this.customersService.create(createCustomerDto);
      return {
        data: customer,
        message: "Customer created successfully",
      };
    } catch (error) {
      console.error("--- Create Customer Error ---");
      console.error(error);
      return {
        statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
        message: error.message,
      };
    }
  }

  @Put(":id")
  async update(
    @Param("id") id: string,
    @Body() updateCustomerDto: UpdateCustomerDto,
  ) {
    try {
      const customer = await this.customersService.update(
        id,
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
  async remove(@Param("id") id: string) {
    const result = await this.customersService.remove(id);
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
  async getStatistics() {
    const stats = await this.customersService.getStatistics();
    return { data: stats };
  }
}
