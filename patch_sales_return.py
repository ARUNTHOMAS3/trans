import os

path = r'lib\app\routing\app_router.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace import
old_import = "import 'package:zerpai_erp/modules/sales/sales_return/presentation/pages/sales_return_create_page.dart';"
new_import = "import 'package:zerpai_erp/modules/sales/sales_return/presentation/pages/sales_return_create_page_new.dart';"
content = content.replace(old_import, new_import)

# Replace builder
old_builder = "builder: (context, state) => const SalesReturnsCreatePage(),"
new_builder = "builder: (context, state) => const SalesReturnsCreatePageNew(),"
content = content.replace(old_builder, new_builder)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched successfully')
