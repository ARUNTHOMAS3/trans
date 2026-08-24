import sys

def replace_in_file(filepath, old_str, new_str):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    if old_str in content:
        content = content.replace(old_str, new_str)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Replaced in {filepath}")
    else:
        print(f"String not found in {filepath}")

# Update module
filepath_mod = 'backend/src/modules/sales/credit-notes/credit-notes.module.ts'
old_mod_import = 'import { SequencesModule } from "../../../sequences/sequences.module";'
new_mod_import = "import { SequencesModule } from '../../../sequences/sequences.module';\nimport { WarehousesSettingsModule } from '../../../warehouses-settings/warehouses-settings.module';"
replace_in_file(filepath_mod, old_mod_import, new_mod_import)

old_mod_imports_arr = 'imports: [SupabaseModule, SequencesModule],'
new_mod_imports_arr = 'imports: [SupabaseModule, SequencesModule, WarehousesSettingsModule],'
replace_in_file(filepath_mod, old_mod_imports_arr, new_mod_imports_arr)

# Update service
filepath_srv = 'backend/src/modules/sales/credit-notes/credit-notes.service.ts'
old_srv_import = 'import { SequencesService } from "../../../sequences/sequences.service";'
new_srv_import = "import { SequencesService } from '../../../sequences/sequences.service';\nimport { WarehousesSettingsService } from '../../../warehouses-settings/warehouses-settings.service';"
replace_in_file(filepath_srv, old_srv_import, new_srv_import)

old_srv_ctor = "constructor(\n    private readonly supabaseService: SupabaseService,\n    private readonly sequencesService: SequencesService,\n  ) {}"
new_srv_ctor = "constructor(\n    private readonly supabaseService: SupabaseService,\n    private readonly sequencesService: SequencesService,\n    private readonly warehousesSettingsService: WarehousesSettingsService,\n  ) {}"
replace_in_file(filepath_srv, old_srv_ctor, new_srv_ctor)

old_srv_get_wh = "async getWarehouses(tenant: TenantContext) {\n    const { data, error } = await this.supabaseService\n      .getClient()\n      .from('warehouses')\n      .select('*')\n      .eq('entity_id', tenant.entityId)\n      .eq('is_active', true)\n      .order('name', { ascending: true });\n\n    if (error) {\n      throw new BadRequestException(Failed to fetch warehouses: );\n    }\n    return { data };\n  }"
new_srv_get_wh = "async getWarehouses(tenant: TenantContext) {\n    const data = await this.warehousesSettingsService.findAll(tenant);\n    return { data };\n  }"
replace_in_file(filepath_srv, old_srv_get_wh, new_srv_get_wh)

