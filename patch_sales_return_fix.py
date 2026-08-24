import os

path = r'lib\app\routing\app_router.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace builder back to SalesReturnsCreatePage
old_builder = "builder: (context, state) => const SalesReturnsCreatePageNew(),"
new_builder = "builder: (context, state) => const SalesReturnsCreatePage(),"
content = content.replace(old_builder, new_builder)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched successfully')
