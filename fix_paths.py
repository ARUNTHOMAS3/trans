import sys

def replace_in_file(filepath, old_str, new_str):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(old_str, new_str)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Replaced in {filepath}")

# Fix sales-returns.module.ts import
f = 'backend/src/modules/sales/sales-returns/sales-returns.module.ts'
replace_in_file(f, 
    "import { WarehousesSettingsModule } from '../../../modules/warehouses-settings/warehouses-settings.module';", 
    "import { WarehousesSettingsModule } from '../../warehouses-settings/warehouses-settings.module';"
)

# Fix credit-notes.module.ts import
f = 'backend/src/modules/sales/credit-notes/credit-notes.module.ts'
replace_in_file(f, 
    "import { WarehousesSettingsModule } from '../../../warehouses-settings/warehouses-settings.module';", 
    "import { WarehousesSettingsModule } from '../../warehouses-settings/warehouses-settings.module';"
)

# Fix credit-notes.service.ts import
f = 'backend/src/modules/sales/credit-notes/credit-notes.service.ts'
replace_in_file(f, 
    "import { WarehousesSettingsService } from '../../../warehouses-settings/warehouses-settings.service';", 
    "import { WarehousesSettingsService } from '../../warehouses-settings/warehouses-settings.service';"
)

# Re-add getWarehouses to sales-returns.service.ts
f = 'backend/src/modules/sales/sales-returns/services/sales-returns.service.ts'
old = """  private escapeRegExp(value: string) {"""
new = """  async getWarehouses(tenant: TenantContext) {
    const data = await this.warehousesSettingsService.findAll(tenant);
    return { data };
  }

  private escapeRegExp(value: string) {"""
replace_in_file(f, old, new)

