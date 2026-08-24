import os

# Backend - Service
path = 'backend/src/modules/reports/reports.service.ts'
old_path = r'C:\Users\ansha\Desktop\zerpai-new-old\backend\src\modules\reports\reports.service.ts'
try:
    with open(old_path, 'r', encoding='utf-8') as f:
        old_content = f.read()
    start_idx = old_content.find('async getHorizontalBalanceSheet(')
    if start_idx != -1:
        # Find the end of the class. It's the last closing brace.
        end_idx = old_content.find('async getTaxSummaryReport(', start_idx) # Let's just extract the method
        if end_idx == -1:
            # If not found, just get to the end of the file minus the class closing brace
            end_idx = old_content.rfind('}')
        method_content = old_content[start_idx:end_idx]
        
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        if 'async getHorizontalBalanceSheet(' not in content:
            last_brace = content.rfind('}')
            content = content[:last_brace] + "  \n  " + method_content + "\n" + content[last_brace:]
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
except Exception as e: print(f"Error service: {e}")

# Backend - Controller
path = 'backend/src/modules/reports/reports.controller.ts'
old_path = r'C:\Users\ansha\Desktop\zerpai-new-old\backend\src\modules\reports\reports.controller.ts'
try:
    with open(old_path, 'r', encoding='utf-8') as f:
        old_content = f.read()
    start_idx = old_content.find('@Get("business-overview/horizontal-balance-sheet")')
    if start_idx != -1:
        end_idx = old_content.find('@Get("business-overview/tax-summary")', start_idx)
        if end_idx == -1:
            end_idx = old_content.rfind('}')
        method_content = old_content[start_idx:end_idx]
        
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        if '@Get("business-overview/horizontal-balance-sheet")' not in content:
            last_brace = content.rfind('}')
            content = content[:last_brace] + "  \n  " + method_content + "\n" + content[last_brace:]
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
except Exception as e: print(f"Error controller: {e}")

# Frontend - Repository
path = 'lib/modules/reports/repositories/reports_repository.dart'
old_path = r'C:\Users\ansha\Desktop\zerpai-new-old\lib\modules\reports\repositories\reports_repository.dart'
try:
    with open(old_path, 'r', encoding='utf-8') as f:
        old_content = f.read()
    start_idx = old_content.find('Future<Map<String, dynamic>> getHorizontalBalanceSheet(')
    if start_idx != -1:
        end_idx = old_content.find('Future<Map<String, dynamic>> getTaxSummaryReport(', start_idx)
        if end_idx == -1:
            end_idx = old_content.rfind('}')
        method_content = old_content[start_idx:end_idx]
        
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        if 'getHorizontalBalanceSheet(' not in content:
            last_brace = content.rfind('}')
            content = content[:last_brace] + "  \n  " + method_content + "\n" + content[last_brace:]
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
except Exception as e: print(f"Error repository: {e}")

