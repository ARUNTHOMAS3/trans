import os

pages_dir = r'e:\zerpai-new\lib\core\pages'

def patch_file(filename, patterns):
    path = os.path.join(pages_dir, filename)
    if not os.path.exists(path):
        print(f"File not found: {filename}")
        return
    
    with open(path, 'rb') as f:
        content = f.read().decode('utf-8')
    
    original = content
    for old, new in patterns:
        # Normalize line endings to find correctly
        old_normalized = old.replace('\n', '\r\n')
        new_normalized = new.replace('\n', '\r\n')
        
        if old_normalized in content:
           content = content.replace(old_normalized, new_normalized)
        elif old in content:
           content = content.replace(old, new)
        else:
           print(f"Pattern not found in {filename}: {repr(old)[:40]}...")

    if content != original:
        with open(path, 'wb') as f:
            f.write(content.encode('utf-8'))
        print(f"Patched {filename}")
    else:
        print(f"No changes for {filename}")

# Fix patterns
patch_file('settings_warehouses_create_page.dart', [
    (
        'if (_isLoading) return const Center(child: CircularProgressIndicator());',
        'if (_isLoading) {\n      return Skeletonizer(\n        ignoreContainers: true,\n        child: SingleChildScrollView(\n          padding: const EdgeInsets.all(AppTheme.space32),\n          child: const ZFormSkeleton(rows: 20),\n        ),\n      );\n    }'
    )
])

patch_file('settings_warehouses_list_page.dart', [
    (
        '          if (_isLoading)\n            const Padding(\n              padding: EdgeInsets.all(AppTheme.space32),\n              child: Center(child: CircularProgressIndicator()),\n            )',
        '          if (_isLoading)\n            const Padding(\n              padding: EdgeInsets.all(AppTheme.space32),\n              child: ZTableSkeleton(rows: 10, columns: 5),\n            )'
    )
])

patch_file('settings_locations_page.dart', [
    (
        '          if (_isLoading && _locations.isEmpty)\n            const Padding(\n              padding: EdgeInsets.all(AppTheme.space32),\n              child: Center(child: CircularProgressIndicator()),\n            )',
        '          if (_isLoading && _locations.isEmpty)\n            const Padding(\n              padding: EdgeInsets.all(AppTheme.space32),\n              child: ZTableSkeleton(rows: 10, columns: 6),\n            )'
    )
])

patch_file('settings_locations_create_page.dart', [
    (
        'if (_isLoading) return const Center(child: CircularProgressIndicator());',
        'if (_isLoading) {\n      return Skeletonizer(\n        ignoreContainers: true,\n        child: SingleChildScrollView(\n          padding: const EdgeInsets.all(AppTheme.space32),\n          child: const ZFormSkeleton(rows: 20),\n        ),\n      );\n    }'
    )
])

patch_file('settings_roles_page.dart', [
    (
        '              ? const Center(child: CircularProgressIndicator())',
        '              ? Skeletonizer(ignoreContainers: true, child: ZTableSkeleton(rows: 10, columns: 4))'
    )
])

patch_file('settings_branches_list_page.dart', [
    (
        '          if (_isLoading)\n            const Padding(\n              padding: EdgeInsets.all(AppTheme.space32),\n              child: Center(child: CircularProgressIndicator()),\n            )',
        '          if (_isLoading)\n            const Padding(\n              padding: EdgeInsets.all(AppTheme.space32),\n              child: ZTableSkeleton(rows: 10, columns: 5),\n            )'
    )
])

for f in ['settings_branding_page.dart', 'settings_organization_branding_page.dart']:
    patch_file(f, [
        (
            'if (_isLoading) return const Center(child: CircularProgressIndicator());',
            'if (_isLoading) {\n      return Skeletonizer(\n        ignoreContainers: true,\n        child: SingleChildScrollView(\n          padding: const EdgeInsets.all(AppTheme.space32),\n          child: const ZFormSkeleton(rows: 20),\n        ),\n      );\n    }'
        )
    ])

print("Batch Skeletonizer migration complete.")
