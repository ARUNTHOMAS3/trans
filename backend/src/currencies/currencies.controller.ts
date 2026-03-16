import { Controller, Get } from "@nestjs/common";
import { CurrenciesService } from "./currencies.service";

@Controller("currencies")
export class CurrenciesController {
  constructor(private readonly currenciesService: CurrenciesService) {}

  @Get()
  async findAll() {
    return this.currenciesService.findAll();
  }
}
