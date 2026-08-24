import os

path = 'backend/src/modules/reports/reports.controller.ts'
old_path = r'C:\Users\ansha\Desktop\zerpai-new-old\backend\src\modules\reports\reports.controller.ts'
with open(old_path, 'r', encoding='utf-8') as f:
    old_content = f.read()

start_idx = old_content.find('getHorizontalBalanceSheet(\n')
if start_idx == -1: start_idx = old_content.find('getHorizontalBalanceSheet(')

# The method should end with a closing brace on a new line followed by empty lines
# Let's extract the method using basic counting of braces.
if start_idx != -1:
    # go back to the @Get decorator
    start_idx = old_content.rfind('@Get', 0, start_idx)
    
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
        content = content[:last_brace] + "\  \n  " + method_content + "\n" + content[last_brace:]
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Controller patched successfully.")

path = 'backend/src/modules/reports/reports.service.ts'
old_path = r'C:\Users\ansha\Desktop\zerpai-new-old\backend\src\modules\reports\reports.service.ts'
with open(old_path, 'r', encoding='utf-8') as f:
    old_content = f.read()

start_idx = old_content.find('async getHorizontalBalanceSheet(')
if start_idx != -1:
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
        print("Service patched successfully.")
