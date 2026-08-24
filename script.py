import sys

def replace_in_file(filepath, old_str, new_str):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(old_str, new_str)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

filepath = 'backend/src/modules/sales/sales-returns/services/sales-returns.service.ts'

old_import = "import { CreateSalesReturnReceiveDto } from '../dto/create-sales-return-receive.dto';"
new_import = "import { CreateSalesReturnReceiveDto } from '../dto/create-sales-return-receive.dto';\nimport { WarehousesSettingsService } from '../../../warehouses-settings/warehouses-settings.service';"
replace_in_file(filepath, old_import, new_import)

old_ctor = "constructor(private readonly supabaseService: SupabaseService) {}"
new_ctor = "constructor(\n    private readonly supabaseService: SupabaseService,\n    private readonly warehousesSettingsService: WarehousesSettingsService,\n  ) {}"
replace_in_file(filepath, old_ctor, new_ctor)

old_get_wh = "async getWarehouses(tenant: TenantContext) {\n    const { data, error } = await this.supabaseService\n      .getClient()\n      .from('warehouses')\n      .select('*')\n      .eq('entity_id', tenant.entityId)\n      .eq('is_active', true)\n      .order('name', { ascending: true });\n\n    if (error) {\n      throw new BadRequestException(Failed to fetch warehouses: );\n    }\n    return { data };\n  }"
new_get_wh = "async getWarehouses(tenant: TenantContext) {\n    const data = await this.warehousesSettingsService.findAll(tenant);\n    return { data };\n  }"
replace_in_file(filepath, old_get_wh, new_get_wh)
