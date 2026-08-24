import os
import difflib

def compare_dirs(dir1, dir2, out_file):
    diff_output = []
    
    for root, _, files in os.walk(dir1):
        for file in files:
            if not file.endswith('.ts') and not file.endswith('.dart'): continue
            
            path1 = os.path.join(root, file)
            rel_path = os.path.relpath(path1, dir1)
            path2 = os.path.join(dir2, rel_path)
            
            if not os.path.exists(path2):
                diff_output.append(f'--- ONLY IN OLD: {rel_path}\n')
                continue
                
            try:
                with open(path1, 'r', encoding='utf-8') as f1, open(path2, 'r', encoding='utf-8') as f2:
                    lines1 = f1.readlines()
                    lines2 = f2.readlines()
                    
                diff = list(difflib.unified_diff(lines2, lines1, fromfile=f'NEW/{rel_path}', tofile=f'OLD/{rel_path}', n=0))
                if diff:
                    diff_output.append(f'--- DIFFERENCES IN {rel_path} ---\n')
                    diff_output.extend(diff[:30]) # keep it short
                    if len(diff) > 30:
                        diff_output.append('... truncated ...\n')
            except Exception as e:
                diff_output.append(f'Error reading {rel_path}: {e}\n')
                
    with open(out_file, 'w', encoding='utf-8') as f:
        f.writelines(diff_output)

compare_dirs(r'C:\Users\ansha\Desktop\zerpai-new-old\backend\src\modules\sales\sales-returns', r'backend\src\modules\sales\sales-returns', 'diff_sales_returns_backend.txt')
compare_dirs(r'C:\Users\ansha\Desktop\zerpai-new-old\backend\src\modules\sales\credit-notes', r'backend\src\modules\sales\credit-notes', 'diff_credit_notes_backend.txt')
compare_dirs(r'C:\Users\ansha\Desktop\zerpai-new-old\backend\src\modules\reports', r'backend\src\modules\reports', 'diff_reports_backend.txt')
