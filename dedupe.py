import re
def fix_duplicate_imports(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    seen = set()
    new_lines = []
    for line in lines:
        if line.startswith('import '):
            if line in seen:
                continue
            seen.add(line)
        new_lines.append(line)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

fix_duplicate_imports('lib/modules/sales/credit_note/presentation/pages/credit_note_create_page.dart')
fix_duplicate_imports('lib/modules/sales/sales_return/presentation/pages/sales_return_create_page_new.dart')
fix_duplicate_imports('lib/modules/sales/sales_return/presentation/pages/sales_return_overview_page.dart')
