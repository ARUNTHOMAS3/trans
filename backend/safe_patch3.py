import os

path = 'src/modules/reports/reports.service.ts'
old_path = r'C:\Users\ansha\Desktop\zerpai-new-old\backend\src\modules\reports\reports.service.ts'
with open(old_path, 'r', encoding='utf-8') as f:
    old_content = f.read()

start_idx = old_content.find('buildBalanceSheetSections(')
if start_idx == -1: start_idx = old_content.find('private buildBalanceSheetSections(')

if start_idx != -1:
    start_idx = old_content.rfind('private', 0, start_idx)
    if start_idx == -1: start_idx = old_content.rfind('buildBalanceSheetSections(', 0, start_idx)

    braces = 0
    in_method = False
    end_idx = -1
    for i in range(start_idx, len(old_content)):
        if old_content[i] == '{':
            braces += 1
            in_method = True
        elif old_content[i] == '}':
            braces -= 1
            if in_method and braces == 0:
                end_idx = i + 1
                break
                
    method_content = old_content[start_idx:end_idx]
    
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if method_content not in content:
        last_brace = content.rfind('}')
        content = content[:last_brace] + "  \n  " + method_content + "\n" + content[last_brace:]
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Service patched successfully with helper method.")
